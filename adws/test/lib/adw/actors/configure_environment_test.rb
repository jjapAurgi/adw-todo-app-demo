# frozen_string_literal: true

require_relative "../../../test_helper"

class ConfigureEnvironmentTest < Minitest::Test
  include TestFactories

  def setup
    @issue_number = 42
    @adw_id = "abc12345"
    @logger = build_logger
    @worktree_path = "/abs/path/trees/feat-42-abc12345-add-login"
    @tracker = build_workflow_tracker
    @issue_tracker_data = build_issue_tracker

    Adw::Tracker.stubs(:update)
    Adw::Tracker.stubs(:save)
    Adw::Tracker::Issue.stubs(:sync)
  end

  def test_parses_port_json_and_updates_issue_tracker
    json = '{"postgres_port":5742,"backend_port":8342,"frontend_port":9342,"compose_project":"adw-feat-42"}'
    Open3.stubs(:capture3).returns([json, "", mock_success_status])

    result = Adw::Actors::ConfigureEnvironment.result(
      issue_number: @issue_number,
      adw_id: @adw_id,
      logger: @logger,
      worktree_path: @worktree_path,
      tracker: @tracker,
      issue_tracker: @issue_tracker_data
    )

    assert result.success?
    assert_equal 5742, result.issue_tracker[:postgres_port]
    assert_equal 8342, result.issue_tracker[:backend_port]
    assert_equal 9342, result.issue_tracker[:frontend_port]
    assert_equal "adw-feat-42", result.issue_tracker[:compose_project]
  end

  def test_fails_on_script_error
    Open3.stubs(:capture3).returns(["", "openssl not found", mock_failure_status])

    result = Adw::Actors::ConfigureEnvironment.result(
      issue_number: @issue_number,
      adw_id: @adw_id,
      logger: @logger,
      worktree_path: @worktree_path,
      tracker: @tracker,
      issue_tracker: @issue_tracker_data
    )

    refute result.success?
    assert_match(/Environment configuration failed/, result.error)
  end

  def test_deterministic_via_script
    json = '{"postgres_port":5742,"backend_port":8342,"frontend_port":9342,"compose_project":"adw-feat-42"}'
    Open3.stubs(:capture3).returns([json, "", mock_success_status])

    result1 = Adw::Actors::ConfigureEnvironment.result(
      issue_number: @issue_number, adw_id: @adw_id, logger: @logger,
      worktree_path: @worktree_path, tracker: build_workflow_tracker,
      issue_tracker: build_issue_tracker
    )

    result2 = Adw::Actors::ConfigureEnvironment.result(
      issue_number: @issue_number, adw_id: @adw_id, logger: @logger,
      worktree_path: @worktree_path, tracker: build_workflow_tracker,
      issue_tracker: build_issue_tracker
    )

    assert_equal result1.issue_tracker[:postgres_port], result2.issue_tracker[:postgres_port]
    assert_equal result1.issue_tracker[:backend_port], result2.issue_tracker[:backend_port]
    assert_equal result1.issue_tracker[:frontend_port], result2.issue_tracker[:frontend_port]
    assert_equal result1.issue_tracker[:compose_project], result2.issue_tracker[:compose_project]
  end

  private

  def mock_success_status
    status = mock("status")
    status.stubs(:success?).returns(true)
    status
  end

  def mock_failure_status
    status = mock("status")
    status.stubs(:success?).returns(false)
    status
  end
end
