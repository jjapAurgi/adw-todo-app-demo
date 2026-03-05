# frozen_string_literal: true

require_relative "../../../test_helper"

class CreateBranchTest < Minitest::Test
  include TestFactories

  def setup
    @issue_number = 42
    @adw_id = "abc12345"
    @logger = build_logger
    @issue = build_issue(number: @issue_number)
    @tracker = build_workflow_tracker
    @issue_tracker_data = build_issue_tracker

    Adw::Tracker.stubs(:update)
    Adw::Tracker::Issue.stubs(:sync)
  end

  def test_returns_branch_name_and_updates_issue_tracker_on_success
    Adw::Agent.stubs(:execute_template).returns(build_agent_response(output: "feature/my-branch-42", success: true))
    Open3.stubs(:capture3).with("git", "checkout", "feature/my-branch-42").returns(["", "", stub(success?: true)])

    result = Adw::Actors::CreateBranch.result(
      issue_number: @issue_number,
      adw_id: @adw_id,
      logger: @logger,
      issue: @issue,
      issue_command: "/feature",
      tracker: @tracker,
      issue_tracker: @issue_tracker_data
    )

    assert result.success?
    assert_equal "feature/my-branch-42", result.branch_name
    assert_equal "feature/my-branch-42", result.issue_tracker[:branch_name]
  end

  def test_fails_when_agent_fails
    Adw::Agent.stubs(:execute_template).returns(build_agent_response(output: "git error", success: false))

    result = Adw::Actors::CreateBranch.result(
      issue_number: @issue_number,
      adw_id: @adw_id,
      logger: @logger,
      issue: @issue,
      issue_command: "/feature",
      tracker: @tracker,
      issue_tracker: @issue_tracker_data
    )

    refute result.success?
    assert_match(/Branch creation failed/, result.error)
  end

  def test_fails_when_git_checkout_fails
    Adw::Agent.stubs(:execute_template).returns(build_agent_response(output: "feature/my-branch-42", success: true))
    Open3.stubs(:capture3).with("git", "checkout", "feature/my-branch-42").returns(["", "error: pathspec not found", stub(success?: false)])

    result = Adw::Actors::CreateBranch.result(
      issue_number: @issue_number,
      adw_id: @adw_id,
      logger: @logger,
      issue: @issue,
      issue_command: "/feature",
      tracker: @tracker,
      issue_tracker: @issue_tracker_data
    )

    refute result.success?
    assert_match(/Git checkout failed/, result.error)
  end
end
