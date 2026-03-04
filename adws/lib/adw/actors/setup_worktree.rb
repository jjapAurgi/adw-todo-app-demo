# frozen_string_literal: true

module Adw
  module Actors
    class SetupWorktree < Actor
      input :issue_number
      input :adw_id
      input :logger
      input :tracker
      input :branch_name
      output :tracker
      output :worktree_path

      play Adw::Actors::CreateWorktree,
           Adw::Actors::ConfigureWorktree,
           Adw::Actors::StartWorktreeEnv
    end
  end
end
