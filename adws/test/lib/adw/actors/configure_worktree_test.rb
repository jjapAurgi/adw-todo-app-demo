# frozen_string_literal: true

require_relative "../../../test_helper"

class ConfigureWorktreeTest < Minitest::Test
  include TestFactories

  def setup
    @issue_number = 42
    @adw_id = "abc12345"
    @logger = build_logger
    @branch_name = "feat-42-abc12345-add-login"
    @worktree_path = "/abs/path/trees/#{@branch_name}"
    @tracker = build_tracker

    Adw::Tracker.stubs(:update)
    Adw::Tracker.stubs(:save)
  end

  def test_parses_port_json_and_updates_tracker
    json = '{"postgres_port": 5742, "backend_port": 8342, "frontend_port": 9342, "compose_project": "adw-feat-42"}'
    Adw::Agent.stubs(:execute_template).returns(build_agent_response(output: json, success: true))

    result = Adw::Actors::ConfigureWorktree.result(
      issue_number: @issue_number,
      adw_id: @adw_id,
      logger: @logger,
      branch_name: @branch_name,
      worktree_path: @worktree_path,
      tracker: @tracker
    )

    assert result.success?
    assert_equal 5742, result.tracker[:postgres_port]
    assert_equal 8342, result.tracker[:backend_port]
    assert_equal 9342, result.tracker[:frontend_port]
    assert_equal "adw-feat-42", result.tracker[:compose_project]
  end

  def test_fallback_to_local_calculation_on_bad_json
    Adw::Agent.stubs(:execute_template).returns(build_agent_response(output: "not valid json", success: true))

    result = Adw::Actors::ConfigureWorktree.result(
      issue_number: @issue_number,
      adw_id: @adw_id,
      logger: @logger,
      branch_name: @branch_name,
      worktree_path: @worktree_path,
      tracker: @tracker
    )

    assert result.success?
    assert_operator result.tracker[:postgres_port], :>=, 5400
    assert_operator result.tracker[:postgres_port], :<=, 6299
    assert_operator result.tracker[:backend_port], :>=, 8000
    assert_operator result.tracker[:backend_port], :<=, 8899
    assert_operator result.tracker[:frontend_port], :>=, 9000
    assert_operator result.tracker[:frontend_port], :<=, 9899
    assert result.tracker[:compose_project].start_with?("adw-")
  end

  def test_deterministic_ports
    json = '{"postgres_port": 5742, "backend_port": 8342, "frontend_port": 9342, "compose_project": "adw-feat-42"}'
    Adw::Agent.stubs(:execute_template).returns(build_agent_response(output: "bad json", success: true))

    result1 = Adw::Actors::ConfigureWorktree.result(
      issue_number: @issue_number,
      adw_id: @adw_id,
      logger: @logger,
      branch_name: @branch_name,
      worktree_path: @worktree_path,
      tracker: build_tracker
    )

    result2 = Adw::Actors::ConfigureWorktree.result(
      issue_number: @issue_number,
      adw_id: @adw_id,
      logger: @logger,
      branch_name: @branch_name,
      worktree_path: @worktree_path,
      tracker: build_tracker
    )

    assert_equal result1.tracker[:postgres_port],   result2.tracker[:postgres_port]
    assert_equal result1.tracker[:backend_port],    result2.tracker[:backend_port]
    assert_equal result1.tracker[:frontend_port],   result2.tracker[:frontend_port]
    assert_equal result1.tracker[:compose_project], result2.tracker[:compose_project]
  end
end
