# frozen_string_literal: true

require_relative "../../../test_helper"

class StartWorktreeEnvTest < Minitest::Test
  include TestFactories

  def setup
    @issue_number = 42
    @adw_id = "abc12345"
    @logger = build_logger
    @worktree_path = "/abs/path/trees/feat-42-abc12345-add-login"
    @tracker = build_tracker
  end

  def test_updates_tracker_to_setting_up
    Adw::Tracker.expects(:update).with(@tracker, @issue_number, "setting_up", @logger)
    Adw::Tracker.stubs(:save)
    Adw::Agent.stubs(:execute_template).returns(build_agent_response(output: "started", success: true))

    result = Adw::Actors::StartWorktreeEnv.result(
      issue_number: @issue_number,
      adw_id: @adw_id,
      logger: @logger,
      worktree_path: @worktree_path,
      tracker: @tracker
    )

    assert result.success?
  end

  def test_service_failure_is_non_blocking
    Adw::Tracker.stubs(:update)
    Adw::Tracker.stubs(:save)
    Adw::Agent.stubs(:execute_template).returns(build_agent_response(output: "docker error", success: false))

    result = Adw::Actors::StartWorktreeEnv.result(
      issue_number: @issue_number,
      adw_id: @adw_id,
      logger: @logger,
      worktree_path: @worktree_path,
      tracker: @tracker
    )

    assert result.success?
  end
end
