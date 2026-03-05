# frozen_string_literal: true

module Adw
  module Actors
    # Builds a patch plan from a human comment.
    # Expects the patch context to be already initialized (by InitializePatchContext),
    # so tracker is the patch_tracker and adw_id is the patch_adw_id.
    class BuildPatchPlan < Actor
      include Adw::Actors::PipelineInputs

      input :comment_body
      input :tracker             # patch_tracker (with _type: :patch)
      input :main_tracker, default: -> { nil }
      output :tracker
      output :main_tracker
      output :plan_path          # path to the patch plan file (for PublishPlan, ImplementPlan)

      def call
        log_actor("Building patch plan")

        original_plan = Adw::PipelineHelpers.plan_path_for(issue_number)

        # Args must match /adw:patch command spec: $1=adw_id, $2=review_change_request, $3=issue_number, $4=spec_path
        args = [adw_id, comment_body, issue_number.to_s]
        args << original_plan if File.exist?(original_plan)

        request = Adw::AgentTemplateRequest.new(
          agent_name: prefixed_name("planner"),
          slash_command: "/adw:patch",
          args: args,
          issue_number: issue_number,
          adw_id: adw_id,
          model: "opus",
          cwd: worktree_path
        )

        response = Adw::Agent.execute_template(request)

        unless response.success
          Adw::Tracker.update(tracker, issue_number, "error", logger)
          Adw::Tracker.update(main_tracker, issue_number, "done", logger) if main_tracker
          fail!(error: "Patch plan creation failed: #{response.output}")
        end

        # The /adw:patch command returns the actual file path it created
        # (naming: patch-{n}-{descriptive-name}.md, not predictable by the actor)
        patch_file = response.output.strip
        if patch_file.empty?
          patch_file = ".issues/#{issue_number}/patch-#{issue_number}-#{adw_id}.md"
          logger.warn("Agent did not return patch file path, using fallback: #{patch_file}")
        end

        tracker[:patch_file] = patch_file

        # Register patch in main tracker
        if main_tracker
          Adw::Tracker.add_patch(main_tracker, patch_file, nil, tracker[:comment_id], adw_id, logger)
          Adw::Tracker.save(issue_number, main_tracker)
        end

        Adw::Tracker.save(issue_number, tracker) # dispatches to save_patch via _type

        self.plan_path = patch_file
        logger.info("Patch plan created: #{patch_file}")
      end
    end
  end
end
