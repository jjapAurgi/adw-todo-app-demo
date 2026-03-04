# frozen_string_literal: true

require "dotenv"

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

        env_vars = parse_worktree_env(worktree_path)

        request = Adw::AgentTemplateRequest.new(
          agent_name: "worktree_starter",
          slash_command: "/env:worktree:start",
          args: [
            worktree_path,
            env_vars["COMPOSE_PROJECT_NAME"],
            env_vars["POSTGRES_PORT"],
            env_vars["DATABASE_URL"],
            env_vars["PORT"],
            env_vars["VITE_PORT"]
          ],
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

      private

      def parse_worktree_env(worktree_path)
        env_file = File.join(worktree_path, ".env.local")
        return {} unless File.exist?(env_file)

        Dotenv.parse(env_file)
      rescue => e
        logger.warn("[StartWorktreeEnv] Could not parse .env.local: #{e.message}")
        {}
      end
    end
  end
end
