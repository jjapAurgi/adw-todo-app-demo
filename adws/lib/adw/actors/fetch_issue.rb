# frozen_string_literal: true
module Adw
  module Actors
    class FetchIssue < Actor
      include Adw::Actors::PipelineInputs
      output :issue

      def call
        log_actor("Fetching issue ##{issue_number}")
        repo_path = Adw::GitHub.extract_repo_path(Adw::GitHub.repo_url)
        self.issue = Adw::GitHub.fetch_issue(issue_number, repo_path)
        fail!(error: "Could not fetch issue ##{issue_number}") unless issue
      end
    end
  end
end
