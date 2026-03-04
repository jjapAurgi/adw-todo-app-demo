# == Schema Information
#
# Table name: tasks
#
#  id         :bigint           not null, primary key
#  completed  :boolean          default(FALSE), not null
#  due_date   :date
#  position   :integer          not null
#  title      :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require "test_helper"

class TaskTest < ActiveSupport::TestCase
  test "valid task" do
    task = Task.new(title: "Valid task")
    assert task.valid?
  end

  test "completed defaults to false" do
    task = Task.create(title: "New task")
    assert_equal false, task.completed
  end

  test "title presence" do
    task = Task.new(completed: false)
    assert_not task.valid?
    assert_includes task.errors[:title], "can't be blank"
  end

  test "title blank" do
    task = Task.new(title: "")
    assert_not task.valid?
    assert_includes task.errors[:title], "can't be blank"
  end

  test "title too long" do
    task = Task.new(title: "a" * 201)
    assert_not task.valid?
    assert_includes task.errors[:title], "is too long (maximum is 200 characters)"
  end

  test "title max length" do
    task = Task.new(title: "a" * 200)
    assert task.valid?
  end

  test "position defaults to next available" do
    max_position = Task.unscoped.maximum(:position)
    task = Task.create!(title: "New positioned task")
    assert_equal max_position + 1, task.position
  end

  test "tasks are ordered by position" do
    tasks = Task.all
    positions = tasks.map(&:position)
    assert_equal positions.sort, positions
  end

  test "valid task with due_date nil" do
    task = Task.new(title: "Task without due date")
    assert task.valid?
    assert_nil task.due_date
  end

  test "valid task with future due_date" do
    task = Task.new(title: "Task with future date", due_date: 7.days.from_now.to_date)
    assert task.valid?
  end

  test "invalid task with past due_date on create" do
    task = Task.new(title: "Task with past date", due_date: 1.day.ago.to_date)
    assert_not task.valid?
    assert_includes task.errors[:due_date], "must be greater than or equal to #{Date.today}"
  end
end
