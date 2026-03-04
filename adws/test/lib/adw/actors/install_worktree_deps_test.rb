# frozen_string_literal: true

require_relative "../../../test_helper"

class InstallWorktreeDepsTest < Minitest::Test
  include TestFactories

  def setup
    @issue_number = 42
    @adw_id = "abc12345"
    @logger = build_logger
    @worktree_path = "/abs/path/trees/feat-42-abc12345-add-login"
    @tracker = build_tracker

    Adw::Tracker.stubs(:update)
    Adw::Tracker.stubs(:save)
  end

  def test_updates_tracker_to_installing_deps
    Adw::Tracker.expects(:update).with(@tracker, @issue_number, "installing_deps", @logger)
    stub_successful_installs

    result = run_actor

    assert result.success?
  end

  def test_runs_bundle_install_in_backend_dir
    Open3.expects(:capture3).with("bundle", "install", chdir: "#{@worktree_path}/backend")
         .returns(["", "", mock_success_status])
    Open3.expects(:capture3).with("npm", "install", chdir: "#{@worktree_path}/frontend")
         .returns(["", "", mock_success_status])

    result = run_actor

    assert result.success?
  end

  def test_fails_on_bundle_install_error
    Open3.stubs(:capture3).with("bundle", "install", chdir: "#{@worktree_path}/backend")
         .returns(["", "Gemfile not found", mock_failure_status])

    result = run_actor

    refute result.success?
    assert_match(/bundle install failed/, result.error)
  end

  def test_fails_on_npm_install_error
    Open3.stubs(:capture3).with("bundle", "install", chdir: "#{@worktree_path}/backend")
         .returns(["", "", mock_success_status])
    Open3.stubs(:capture3).with("npm", "install", chdir: "#{@worktree_path}/frontend")
         .returns(["", "npm ERR! missing package.json", mock_failure_status])

    result = run_actor

    refute result.success?
    assert_match(/npm install failed/, result.error)
  end

  def test_does_not_run_npm_if_bundle_fails
    Open3.stubs(:capture3).with("bundle", "install", chdir: "#{@worktree_path}/backend")
         .returns(["", "error", mock_failure_status])
    Open3.expects(:capture3).with("npm", "install", chdir: "#{@worktree_path}/frontend").never

    run_actor
  end

  private

  def run_actor
    Adw::Actors::InstallWorktreeDeps.result(
      issue_number: @issue_number,
      adw_id: @adw_id,
      logger: @logger,
      worktree_path: @worktree_path,
      tracker: @tracker
    )
  end

  def stub_successful_installs
    Open3.stubs(:capture3).with("bundle", "install", chdir: "#{@worktree_path}/backend")
         .returns(["", "", mock_success_status])
    Open3.stubs(:capture3).with("npm", "install", chdir: "#{@worktree_path}/frontend")
         .returns(["", "", mock_success_status])
  end

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
