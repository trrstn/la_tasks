defmodule LaTasksWeb.API.TaskControllerTest do
  use LaTasksWeb.ConnCase, async: true

  alias LaTasks.Accounts
  alias LaTasks.Tasks
  alias LaTasks.AccountsFixtures

  defp auth_conn(conn, user) do
    token = Accounts.create_user_api_token(user)

    conn
    |> put_req_header("authorization", "Bearer #{token}")
  end

  describe "GET /api/tasks" do
    test "returns active tasks for current user in order", %{conn: conn} do
      user = AccountsFixtures.user_fixture()
      other_user = AccountsFixtures.user_fixture()

      {:ok, older_task} =
        Tasks.create_task(%{
          user_id: user.id,
          title: "Older task"
        })

      {:ok, newer_task} =
        Tasks.create_task(%{
          user_id: user.id,
          title: "Newer task"
        })

      {:ok, archived_task} =
        Tasks.create_task(%{
          user_id: user.id,
          title: "Archived task"
        })

      {:ok, _} = Tasks.archive_task(archived_task)

      {:ok, _} =
        Tasks.create_task(%{
          user_id: other_user.id,
          title: "Other user task"
        })

      conn =
        conn
        |> auth_conn(user)
        |> get("/api/tasks")

      body = json_response(conn, 200)
      ids = Enum.map(body["data"], & &1["id"])

      assert ids == [newer_task.id, older_task.id]
    end
  end

  describe "POST /api/tasks" do
    test "creates a task", %{conn: conn} do
      user = AccountsFixtures.user_fixture()

      conn =
        conn
        |> auth_conn(user)
        |> post("/api/tasks", %{
          "title" => "Buy milk",
          "description" => "2 liters"
        })

      body = json_response(conn, 201)

      assert body["message"] == "Task created successfully"
      assert body["task"]["title"] == "Buy milk"
      assert body["task"]["user_id"] == user.id
      assert is_binary(body["task"]["rank"])
      assert body["task"]["archived_at"] == nil
    end

    test "returns validation errors", %{conn: conn} do
      user = AccountsFixtures.user_fixture()

      conn =
        conn
        |> auth_conn(user)
        |> post("/api/tasks", %{"title" => ""})

      body = json_response(conn, 422)

      assert body["errors"]["title"] != nil
    end
  end

  describe "PATCH /api/tasks/:id" do
    test "updates task", %{conn: conn} do
      user = AccountsFixtures.user_fixture()

      {:ok, task} =
        Tasks.create_task(%{
          user_id: user.id,
          title: "Old"
        })

      conn =
        conn
        |> auth_conn(user)
        |> patch("/api/tasks/#{task.id}", %{"title" => "New"})

      body = json_response(conn, 200)

      assert body["task"]["title"] == "New"
    end

    test "returns 404 for other user", %{conn: conn} do
      user = AccountsFixtures.user_fixture()
      other_user = AccountsFixtures.user_fixture()

      {:ok, task} =
        Tasks.create_task(%{
          user_id: other_user.id,
          title: "Other"
        })

      conn =
        conn
        |> auth_conn(user)
        |> patch("/api/tasks/#{task.id}", %{"title" => "Hack"})

      body = json_response(conn, 404)

      assert body["error"] == "Task not found"
    end
  end

  describe "PATCH /api/tasks/:id/archive" do
    test "archives task", %{conn: conn} do
      user = AccountsFixtures.user_fixture()

      {:ok, task} =
        Tasks.create_task(%{
          user_id: user.id,
          title: "Task"
        })

      conn =
        conn
        |> auth_conn(user)
        |> patch("/api/tasks/#{task.id}/archive")

      body = json_response(conn, 200)

      assert body["task"]["archived_at"] != nil
    end
  end

  describe "PATCH /api/tasks/reorder" do
    test "moves task to top", %{conn: conn} do
      user = AccountsFixtures.user_fixture()

      {:ok, task_a} =
        Tasks.create_task(%{user_id: user.id, title: "A"})

      {:ok, task_b} =
        Tasks.create_task(%{user_id: user.id, title: "B"})

      {:ok, task_c} =
        Tasks.create_task(%{user_id: user.id, title: "C"})

      conn =
        conn
        |> auth_conn(user)
        |> patch("/api/tasks/reorder", %{
          "task_id" => task_a.id,
          "prev_id" => nil,
          "next_id" => task_c.id
        })

      _ = json_response(conn, 200)

      ids = Enum.map(Tasks.list_active_tasks(user.id), & &1.id)

      assert ids == [task_a.id, task_c.id, task_b.id]
    end

    test "returns bad request when both nil", %{conn: conn} do
      user = AccountsFixtures.user_fixture()

      {:ok, task} =
        Tasks.create_task(%{user_id: user.id, title: "Task"})

      conn =
        conn
        |> auth_conn(user)
        |> patch("/api/tasks/reorder", %{
          "task_id" => task.id
        })

      body = json_response(conn, 400)

      assert body["error"] == "prev_id and next_id cannot both be empty"
    end
  end
end
