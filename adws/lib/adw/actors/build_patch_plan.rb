# frozen_string_literal: true

module Adw
  module Actors
    # Builds a patch plan from a human comment.
    # Expects the patch context to be already initialized (by InitializePatchContext),
    # so tracker is the patch workflow tracker and adw_id is the patch_adw_id.
    class BuildPatchPlan < Actor
      include Adw::Actors::PipelineInputs

      input :comment_body
      input :tracker
      output :tracker
      output :plan_path

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
          fail!(error: "Patch plan creation failed: #{response.output}")
        end

        plan_file = response.output.strip.delete("`")
        if plan_file.empty?
          plan_file = ".issues/#{issue_number}/patch-#{issue_number}-#{adw_id}.md"
          logger.warn("Agent did not return patch file path, using fallback: #{plan_file}")
        end

        tracker[:plan_path] = plan_file
        Adw::Tracker.save(issue_number, tracker)

        self.plan_path = plan_file
        logger.info("Patch plan created: #{plan_file}")
      end
    end
  end
end
