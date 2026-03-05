# frozen_string_literal: true

require "open3"

module Adw
  module Actors
    class CreateWorktree < Actor
      include Adw::Actors::PipelineInputs

      input :tracker, default: -> { {} }
      output :tracker
      output :branch_name
      output :worktree_path

      def call
        tracker[:adw_id] ||= adw_id
        log_actor("Generating branch name and creating worktree")
        Adw::Tracker.update(tracker, issue_number, "creating_worktree", logger)

        name = "issue-#{issue_number}"
        logger.info("Generated branch name: #{name}")

        script = File.join(Adw.project_root, "adws", "bin", "worktree_create")
        stdout, stderr, status = Open3.capture3(script, name)

        unless status.success?
          Adw::Tracker.update(tracker, issue_number, "error", logger)
          fail!(error: "Worktree creation failed: #{stderr.strip}")
        end

        path = stdout.strip
        tracker[:branch_name] = name
        tracker[:worktree_path] = path
        self.branch_name = name
        self.worktree_path = path
        logger.info("Branch #{name} created, worktree at #{path}")
      end
    end
  end
end
