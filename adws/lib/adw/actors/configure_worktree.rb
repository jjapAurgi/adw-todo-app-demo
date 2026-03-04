# frozen_string_literal: true

require "digest"
require "json"

module Adw
  module Actors
    class ConfigureWorktree < Actor
      include Adw::Actors::PipelineInputs

      input :tracker
      input :branch_name
      input :worktree_path
      output :tracker

      PORT_RANGES = { postgres: 5400, backend: 8000, frontend: 9000 }.freeze
      PORT_RANGE  = 900

      def call
        log_actor("Configuring worktree environment for: #{branch_name}")

        request = Adw::AgentTemplateRequest.new(
          agent_name: "worktree_configurator",
          slash_command: "/env:worktree:configure",
          args: [branch_name, worktree_path],
          issue_number: issue_number,
          adw_id: adw_id,
          model: "haiku"
        )

        response = Adw::Agent.execute_template(request)

        unless response.success
          Adw::Tracker.update(tracker, issue_number, "error", logger)
          fail!(error: "Worktree configuration failed: #{response.output}")
        end

        ports = parse_ports(response.output)
        tracker[:backend_port]    = ports[:backend_port]
        tracker[:frontend_port]   = ports[:frontend_port]
        tracker[:postgres_port]   = ports[:postgres_port]
        tracker[:compose_project] = ports[:compose_project]
        Adw::Tracker.save(issue_number, tracker)

        logger.info("Configured — backend: #{ports[:backend_port]}, frontend: #{ports[:frontend_port]}, postgres: #{ports[:postgres_port]}")
      end

      private

      def parse_ports(output)
        data = JSON.parse(output.strip)
        {
          backend_port:    data["backend_port"],
          frontend_port:   data["frontend_port"],
          postgres_port:   data["postgres_port"],
          compose_project: data["compose_project"]
        }
      rescue JSON::ParserError
        logger.warn("[ConfigureWorktree] JSON parse failed — using local calculation")
        calculate_ports_locally
      end

      def calculate_ports_locally
        offset  = Digest::SHA256.hexdigest(branch_name)[0..7].to_i(16) % PORT_RANGE
        project = "adw-#{branch_name.downcase.gsub(/[^a-z0-9-]/, "-")[0..62]}"
        {
          postgres_port:   PORT_RANGES[:postgres]  + offset,
          backend_port:    PORT_RANGES[:backend]   + offset,
          frontend_port:   PORT_RANGES[:frontend]  + offset,
          compose_project: project
        }
      end
    end
  end
end
