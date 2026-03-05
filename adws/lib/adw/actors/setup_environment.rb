# frozen_string_literal: true

module Adw
  module Actors
    class SetupEnvironment < Actor
      input :issue_number
      input :adw_id
      input :logger
      input :tracker, default: -> { {} }
      input :issue_tracker, default: -> { {} }
      input :worktree_path, default: -> { nil }
      input :branch_name, default: -> { nil }
      output :tracker
      output :issue_tracker

      play Adw::Actors::ConfigureEnvironment,
           Adw::Actors::InstallEnvironmentDeps,
           Adw::Actors::StartEnvironment
    end
  end
end
