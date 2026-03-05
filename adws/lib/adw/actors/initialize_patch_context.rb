# frozen_string_literal: true

module Adw
  module Actors
    # Initializes the patch workflow context.
    # Creates a fresh workflow tracker for the patch run and swaps adw_id/logger
    # for downstream actors. The issue_tracker flows through unchanged.
    class InitializePatchContext < Actor
      include Adw::Actors::PipelineInputs

      input :tracker            # workflow tracker from previous run (for label transition)
      input :comment_body

      output :tracker           # replaced with new patch workflow tracker
      output :adw_id            # replaced with patch_adw_id
      output :logger            # replaced with patch_logger
      output :agent_name_prefix # "patch_"

      # Overrides for downstream actors
      output :commit_message    # for CommitChanges
      output :push_blocking     # for PushBranch
      output :title             # for PublishPlan

      # Test actor name overrides (TestWithResolution inputs)
      output :test_agent_name
      output :resolver_prefix
      output :ops_agent_name

      def call
        log_actor("Initializing patch context")

        # Create patch identity
        patch_adw_id = Adw::Utils.make_adw_id
        patch_logger = Adw::Utils.setup_logger(issue_number, patch_adw_id, "adw_patch")

        # Transition current workflow tracker to patching (label transition)
        Adw::Tracker.update(tracker, issue_number, "patching", logger)

        # Create a fresh workflow tracker for the patch
        patch_tracker = Adw::Tracker::Workflow.create(
          adw_id: patch_adw_id,
          workflow_type: "patch",
          trigger_comment: comment_body
        )

        # Register this workflow in the issue tracker
        Adw::Tracker::Issue.add_workflow(issue_tracker, adw_id: patch_adw_id, type: "patch")
        Adw::Tracker::Issue.save(issue_number, issue_tracker)

        # Initialize the patch workflow tracker status
        Adw::Tracker::Workflow.update(patch_tracker, issue_number, "patching", patch_logger)

        # Swap context for downstream actors
        self.tracker = patch_tracker
        self.adw_id = patch_adw_id
        self.logger = patch_logger
        self.agent_name_prefix = "patch_"

        # Configure downstream actors
        self.commit_message = "patch: apply human feedback for ##{issue_number}"
        self.push_blocking = false
        self.title = "Patch Plan"

        # Test actor overrides
        self.test_agent_name = "patch_test_runner"
        self.resolver_prefix = "patch_test_resolver"
        self.ops_agent_name = "patch_ops"

        patch_logger.info("Patch context initialized: patch_adw_id=#{patch_adw_id}")
      end
    end
  end
end
