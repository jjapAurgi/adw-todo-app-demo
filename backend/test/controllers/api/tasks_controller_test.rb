require "test_helper"

class Api::TasksControllerTest < ActionDispatch::IntegrationTest
  # Test para GET /api/tasks (index)
  test "should get index with all tasks" do
    get api_tasks_url, as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_instance_of Array, json_response
    assert_equal 3, json_response.length

    # Verificar estructura de cada tarea
    json_response.each do |task|
      assert task.key?("id")
      assert task.key?("title")
      assert task.key?("completed")
      assert task.key?("created_at")
      assert task.key?("updated_at")
    end
  end

  # Test para POST /api/tasks (create) exitoso
  test "should create task with valid data" do
    assert_difference("Task.count", 1) do
      post api_tasks_url, params: { task: { title: "New task from test" } }, as: :json
    end

    assert_response :created
    json_response = JSON.parse(response.body)
    assert_equal "New task from test", json_response["title"]
    assert_equal false, json_response["completed"]
  end

  # Test para POST /api/tasks con título vacío
  test "should not create task with empty title" do
    assert_no_difference("Task.count") do
      post api_tasks_url, params: { task: { title: "" } }, as: :json
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert json_response.key?("errors")
    assert_instance_of Array, json_response["errors"]
  end

  # Test para POST /api/tasks con título muy largo
  test "should not create task with title too long" do
    long_title = "a" * 201

    assert_no_difference("Task.count") do
      post api_tasks_url, params: { task: { title: long_title } }, as: :json
    end

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert json_response.key?("errors")
    assert_includes json_response["errors"].join, "too long"
  end

  # Test para PATCH /api/tasks/:id (update) exitoso
  test "should update task with valid data" do
    task = tasks(:one)
    patch api_task_url(task), params: { task: { completed: true } }, as: :json

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal true, json_response["completed"]

    # Verificar que se actualizó en la base de datos
    task.reload
    assert task.completed
  end

  # Test para PATCH /api/tasks/:id con datos inválidos
  test "should not update task with invalid data" do
    task = tasks(:one)
    original_title = task.title

    patch api_task_url(task), params: { task: { title: "" } }, as: :json

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert json_response.key?("errors")

    # Verificar que NO se actualizó en la base de datos
    task.reload
    assert_equal original_title, task.title
  end

  # Test para DELETE /api/tasks/:id (destroy) exitoso
  test "should destroy task" do
    task = tasks(:one)

    assert_difference("Task.count", -1) do
      delete api_task_url(task), as: :json
    end

    assert_response :no_content
    assert_empty response.body
  end

  # Test para PATCH con ID no existente
  test "should return 404 when updating non-existent task" do
    patch api_task_url(id: 99999), params: { task: { completed: true } }, as: :json

    assert_response :not_found
    json_response = JSON.parse(response.body)
    assert json_response.key?("error")
    assert_equal "Task not found", json_response["error"]
  end

  # Test para DELETE con ID no existente
  test "should return 404 when deleting non-existent task" do
    delete api_task_url(id: 99999), as: :json

    assert_response :not_found
    json_response = JSON.parse(response.body)
    assert json_response.key?("error")
    assert_equal "Task not found", json_response["error"]
  end

  # Test para PATCH /api/tasks/reorder
  test "should reorder tasks" do
    task_one = tasks(:one)
    task_two = tasks(:two)
    task_three = tasks(:three)

    new_order = [task_three.id, task_one.id, task_two.id]
    patch reorder_api_tasks_url, params: { task_ids: new_order }, as: :json

    assert_response :ok

    assert_equal 0, task_three.reload.position
    assert_equal 1, task_one.reload.position
    assert_equal 2, task_two.reload.position
  end

  test "should return error when task_ids is empty" do
    patch reorder_api_tasks_url, params: { task_ids: [] }, as: :json
    assert_response :unprocessable_entity
  end

  test "index returns tasks ordered by position" do
    get api_tasks_url, as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    positions = json_response.map { |t| t["position"] }
    assert_equal positions.sort, positions
  end

  # Tests de due_date
  test "should create task with due_date" do
    future_date = 5.days.from_now.to_date.to_s

    assert_difference("Task.count", 1) do
      post api_tasks_url, params: { task: { title: "Task with date", due_date: future_date } }, as: :json
    end

    assert_response :created
    json_response = JSON.parse(response.body)
    assert_equal future_date, json_response["due_date"]
  end

  test "should create task without due_date" do
    assert_difference("Task.count", 1) do
      post api_tasks_url, params: { task: { title: "Task without date" } }, as: :json
    end

    assert_response :created
    json_response = JSON.parse(response.body)
    assert_nil json_response["due_date"]
  end

  test "should update due_date of existing task" do
    task = tasks(:one)
    new_date = 10.days.from_now.to_date.to_s

    patch api_task_url(task), params: { task: { due_date: new_date } }, as: :json

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal new_date, json_response["due_date"]

    task.reload
    assert_equal new_date, task.due_date.to_s
  end

  test "should remove due_date by setting to null" do
    task = tasks(:one)
    assert_not_nil task.due_date

    patch api_task_url(task), params: { task: { due_date: nil } }, as: :json

    assert_response :success
    task.reload
    assert_nil task.due_date
  end
end
