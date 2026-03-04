# frozen_string_literal: true

module Adw
  module Actors
    class DestroyWorktree < Actor
      include Adw::Actors::PipelineInputs

      input :tracker
      output :tracker

      def call
        worktree_path = tracker[:worktree_path]
        branch_name   = worktree_path ? File.basename(worktree_path) : nil

        unless worktree_path && Dir.exist?(worktree_path)
          logger.info("[DestroyWorktree] No active worktree found, skipping")
          return
        end

        log_actor("Destroying worktree: #{worktree_path}")

        request = Adw::AgentTemplateRequest.new(
          agent_name: "worktree_destroyer",
          slash_command: "/env:worktree:destroy",
          args: [branch_name],
          issue_number: issue_number,
          adw_id: adw_id,
          model: "sonnet"
        )

        response = Adw::Agent.execute_template(request)
        unless response.success
          logger.warn("[DestroyWorktree] Destroy had issues (non-blocking): #{response.output}")
        end

        tracker.delete(:worktree_path)
        tracker.delete(:backend_port)
        tracker.delete(:frontend_port)
        tracker.delete(:postgres_port)
        tracker.delete(:compose_project)
        Adw::Tracker.save(issue_number, tracker)

        logger.info("Worktree destroyed: #{worktree_path}")
      end
    end
  end
end
