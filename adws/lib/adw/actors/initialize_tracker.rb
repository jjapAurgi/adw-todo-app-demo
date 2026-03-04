# frozen_string_literal: true
module Adw
  module Actors
    class InitializeTracker < Actor
      include Adw::Actors::PipelineInputs
      output :tracker

      def call
        log_actor("Initializing tracker")
        loaded = Adw::Tracker.load(issue_number) || {}
        self.tracker = loaded.merge(adw_id: adw_id)
      end
    end
  end
end
