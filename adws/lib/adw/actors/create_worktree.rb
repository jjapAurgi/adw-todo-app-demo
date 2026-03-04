# frozen_string_literal: true

require "open3"
require "fileutils"

module Adw
  module Actors
    class CreateWorktree < Actor
      include Adw::Actors::PipelineInputs

      input :tracker
      input :branch_name
      output :tracker
      output :worktree_path

      TREES_DIR = "trees"

      def call
        log_actor("Creating worktree for branch: #{branch_name}")

        path = File.join(Adw.project_root, TREES_DIR, branch_name)
        FileUtils.mkdir_p(File.join(Adw.project_root, TREES_DIR))

        request = Adw::AgentTemplateRequest.new(
          agent_name: "worktree_creator",
          slash_command: "/env:worktree:create",
          args: [branch_name],
          issue_number: issue_number,
          adw_id: adw_id,
          model: "haiku"
        )

        response = Adw::Agent.execute_template(request)

        unless response.success
          Adw::Tracker.update(tracker, issue_number, "error", logger)
          fail!(error: "Worktree creation failed: #{response.output}")
        end

        self.worktree_path = path
        tracker[:worktree_path] = path
        logger.info("Worktree created: #{path}")
      end
    end
  end
end
