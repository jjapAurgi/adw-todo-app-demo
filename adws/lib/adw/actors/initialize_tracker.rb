# frozen_string_literal: true
module Adw
  module Actors
    class InitializeTracker < Actor
      include Adw::Actors::PipelineInputs
      input :branch_name, default: -> { nil }
      input :workflow_type, default: -> { "full_pipeline" }
      output :issue_tracker
      output :tracker

      def call
        log_actor("Initializing trackers")

        # Load or create issue tracker
        loaded_issue = Adw::Tracker::Issue.load(issue_number) || {}
        loaded_issue[:branch_name] = branch_name if branch_name
        self.issue_tracker = loaded_issue

        # Create a fresh workflow tracker for this run
        self.tracker = Adw::Tracker::Workflow.create(
          adw_id: adw_id,
          workflow_type: workflow_type
        )
      end
    end
  end
end
