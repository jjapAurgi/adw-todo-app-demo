# frozen_string_literal: true
module Adw
  module Actors
    class ClassifyIssue < Actor
      include Adw::Actors::PipelineInputs
      input :issue
      input :tracker
      output :issue_tracker
      output :tracker
      output :issue_command

      def call
        log_actor("Classifying issue (agent: issue_classifier)")
        Adw::Tracker.update(tracker, issue_number, "classifying", logger)

        request = Adw::AgentTemplateRequest.new(
          agent_name: "issue_classifier",
          slash_command: "/adw:classify_issue",
          args: [issue.to_json],
          issue_number: issue_number,
          adw_id: adw_id,
          model: "sonnet"
        )

        response = Adw::Agent.execute_template(request)

        unless response.success
          Adw::Tracker.update(tracker, issue_number, "error", logger)
          fail!(error: "Issue classification failed: #{response.output}")
        end

        command = response.output.strip

        if command == "none" || !Adw::ISSUE_CLASS_COMMANDS.include?(command)
          Adw::Tracker.update(tracker, issue_number, "error", logger)
          fail!(error: "Invalid classification: #{response.output}")
        end

        issue_tracker[:classification] = command
        Adw::Tracker::Issue.sync(issue_tracker, issue_number, logger)
        self.issue_command = command
      end
    end
  end
end
