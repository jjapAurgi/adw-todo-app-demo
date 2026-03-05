# frozen_string_literal: true

require "open3"
require "json"

module Adw
  module Actors
    class ConfigureEnvironment < Actor
      include Adw::Actors::PipelineInputs

      input :tracker, default: -> { {} }
      output :issue_tracker
      output :tracker

      def call
        path = worktree_path || Adw.project_root
        log_actor("Configuring environment for: #{path}")
        Adw::Tracker.update(tracker, issue_number, "isolating", logger)

        script = File.join(Adw.project_root, "adws", "bin", "worktree", "isolate")
        stdout, stderr, status = Open3.capture3(script, path)

        unless status.success?
          Adw::Tracker.update(tracker, issue_number, "error", logger)
          fail!(error: "Environment configuration failed: #{stderr.strip}")
        end

        ports = JSON.parse(stdout.strip, symbolize_names: true)
        issue_tracker[:backend_port]    = ports[:backend_port]
        issue_tracker[:frontend_port]   = ports[:frontend_port]
        issue_tracker[:postgres_port]   = ports[:postgres_port]
        issue_tracker[:compose_project] = ports[:compose_project]
        Adw::Tracker::Issue.sync(issue_tracker, issue_number, logger)

        logger.info("Configured — backend: #{ports[:backend_port]}, frontend: #{ports[:frontend_port]}, postgres: #{ports[:postgres_port]}")
      end
    end
  end
end
