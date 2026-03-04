# frozen_string_literal: true

module Adw
  module Actors
    class StartWorktreeEnv < Actor
      include Adw::Actors::PipelineInputs

      input :tracker
      input :worktree_path
      output :tracker

      def call
        log_actor("Starting worktree environment: #{worktree_path}")
        Adw::Tracker.update(tracker, issue_number, "setting_up", logger)

        request = Adw::AgentTemplateRequest.new(
          agent_name: "worktree_starter",
          slash_command: "/env:worktree:start",
          args: [worktree_path],
          issue_number: issue_number,
          adw_id: adw_id,
          model: "sonnet"
        )

        response = Adw::Agent.execute_template(request)
        unless response.success
          logger.warn("[StartWorktreeEnv] Services failed to start (non-blocking): #{response.output}")
        end
      rescue => e
        logger.warn("[StartWorktreeEnv] Exception starting services (non-blocking): #{e.message}")
      end
    end
  end
end
