# frozen_string_literal: true

require_relative "../../../test_helper"

class InitializeTrackerTest < Minitest::Test
  include TestFactories

  def setup
    @issue_number = 42
    @adw_id = "abc12345"
    @logger = build_logger
  end

  def test_loads_existing_issue_tracker_and_creates_workflow_tracker
    existing_issue = { classification: "/feature", branch_name: "feature/test" }
    Adw::Tracker::Issue.stubs(:load).with(@issue_number).returns(existing_issue)

    result = Adw::Actors::InitializeTracker.result(
      issue_number: @issue_number,
      adw_id: @adw_id,
      logger: @logger
    )

    assert result.success?
    assert_equal "/feature", result.issue_tracker[:classification]
    assert_equal "feature/test", result.issue_tracker[:branch_name]
    assert_equal @adw_id, result.tracker[:adw_id]
    assert_equal "full_pipeline", result.tracker[:workflow_type]
  end

  def test_creates_empty_issue_tracker_when_load_returns_nil
    Adw::Tracker::Issue.stubs(:load).with(@issue_number).returns(nil)

    result = Adw::Actors::InitializeTracker.result(
      issue_number: @issue_number,
      adw_id: @adw_id,
      logger: @logger
    )

    assert result.success?
    assert_equal({}, result.issue_tracker)
    assert_equal @adw_id, result.tracker[:adw_id]
  end

  def test_sets_branch_name_on_issue_tracker_when_provided
    Adw::Tracker::Issue.stubs(:load).with(@issue_number).returns({})

    result = Adw::Actors::InitializeTracker.result(
      issue_number: @issue_number,
      adw_id: @adw_id,
      logger: @logger,
      branch_name: "feature-42-abc12345-test"
    )

    assert result.success?
    assert_equal "feature-42-abc12345-test", result.issue_tracker[:branch_name]
  end

  def test_uses_custom_workflow_type
    Adw::Tracker::Issue.stubs(:load).with(@issue_number).returns(nil)

    result = Adw::Actors::InitializeTracker.result(
      issue_number: @issue_number,
      adw_id: @adw_id,
      logger: @logger,
      workflow_type: "plan_build"
    )

    assert result.success?
    assert_equal "plan_build", result.tracker[:workflow_type]
  end
end
