# frozen_string_literal: true
module Adw
  module Actors
    class CreateBranch < Actor
      include Adw::Actors::PipelineInputs
      input :issue
      input :issue_command
      input :tracker
      output :tracker
      output :branch_name

      def call
        log_actor("Creating branch (agent: branch_generator)")
        issue_type = issue_command.delete_prefix("/")

        request = Adw::AgentTemplateRequest.new(
          agent_name: "branch_generator",
          slash_command: "/adw:generate_branch_name",
          args: [issue_type, adw_id, issue.to_json],
          issue_number: issue_number,
          adw_id: adw_id,
          model: "sonnet"
        )

        response = Adw::Agent.execute_template(request)

        unless response.success
          Adw::Tracker.update(tracker, issue_number, "error", logger)
          fail!(error: "Branch creation failed: #{response.output}")
        end

        name = response.output.strip
        tracker[:branch_name] = name
        self.branch_name = name
        logger.info("Created branch: #{name}")
      end
    end
  end
end
