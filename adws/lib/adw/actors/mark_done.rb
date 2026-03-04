# frozen_string_literal: true

module Adw
  module Actors
    class MarkDone < Actor
      include Adw::Actors::PipelineInputs

      input :tracker
      output :tracker

      def call
        log_actor("Marking workflow as done")
        Adw::Tracker.update(tracker, issue_number, "done", logger)
        logger.info("Workflow marked as done for issue ##{issue_number}")
      end
    end
  end
end
