# frozen_string_literal: true

require_relative "../../../test_helper"

class CreateWorktreeTest < Minitest::Test
  include TestFactories

  def setup
    @issue_number = 42
    @adw_id = "abc12345"
    @logger = build_logger
    @branch_name = "feat-42-abc12345-add-login"
    @tracker = build_tracker

    Adw::Tracker.stubs(:update)
    Adw::Tracker.stubs(:save)
  end

  def test_creates_worktree_and_sets_outputs
    Adw::Agent.stubs(:execute_template).returns(build_agent_response(output: "/abs/path/trees/#{@branch_name}", success: true))

    result = Adw::Actors::CreateWorktree.result(
      issue_number: @issue_number,
      adw_id: @adw_id,
      logger: @logger,
      branch_name: @branch_name,
      tracker: @tracker
    )

    assert result.success?
    assert result.worktree_path.end_with?(@branch_name)
    assert result.tracker[:worktree_path].end_with?(@branch_name)
  end

  def test_fails_when_agent_fails
    Adw::Agent.stubs(:execute_template).returns(build_agent_response(output: "git error", success: false))

    result = Adw::Actors::CreateWorktree.result(
      issue_number: @issue_number,
      adw_id: @adw_id,
      logger: @logger,
      branch_name: @branch_name,
      tracker: @tracker
    )

    refute result.success?
    assert_match(/Worktree creation failed/, result.error)
  end
end
