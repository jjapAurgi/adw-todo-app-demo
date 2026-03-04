# frozen_string_literal: true

require "open3"

module Adw
  module Actors
    class InstallWorktreeDeps < Actor
      include Adw::Actors::PipelineInputs

      input :tracker
      input :worktree_path
      output :tracker

      def call
        log_actor("Installing dependencies in worktree: #{worktree_path}")
        Adw::Tracker.update(tracker, issue_number, "installing_deps", logger)

        install_backend_deps
        install_frontend_deps

        logger.info("Dependencies installed successfully")
      end

      private

      def install_backend_deps
        backend_dir = File.join(worktree_path, "backend")
        _, stderr, status = Open3.capture3("bundle", "install", chdir: backend_dir)
        unless status.success?
          Adw::Tracker.update(tracker, issue_number, "error", logger)
          fail!(error: "bundle install failed: #{stderr.strip}")
        end
      end

      def install_frontend_deps
        frontend_dir = File.join(worktree_path, "frontend")
        _, stderr, status = Open3.capture3("npm", "install", chdir: frontend_dir)
        unless status.success?
          Adw::Tracker.update(tracker, issue_number, "error", logger)
          fail!(error: "npm install failed: #{stderr.strip}")
        end
      end
    end
  end
end
