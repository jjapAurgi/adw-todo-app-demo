# frozen_string_literal: true

module Adw
  module Workflows
    class PlanBuildTest < Actor
      input :issue_number
      input :adw_id
      input :logger
      input :workflow_type, default: -> { "plan_build_test" }

      play Adw::Workflows::PlanBuild,
           Adw::Actors::TestWithResolution,
           Adw::Actors::PublishTestResults,
           Adw::Actors::CommitChanges,
           Adw::Actors::PushBranch,
           Adw::Actors::MarkDone
    end
  end
end
