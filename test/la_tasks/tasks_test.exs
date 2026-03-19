defmodule LaTasks.TasksTest do
  use LaTasks.DataCase, async: true

  alias LaTasks.Tasks
  alias LaTasks.Tasks.Task

  alias LaTasks.AccountsFixtures

  describe "tasks" do
    setup do
      user = AccountsFixtures.user_fixture()

      %{user: user}
    end

    test "create_task/1 creates a task for the user", %{user: user} do
      assert {:ok, %Task{} = task} =
               Tasks.create_task(%{
                 user_id: user.id,
                 title: "First task",
                 description: "Test description"
               })

      assert task.user_id == user.id
      assert task.title == "First task"
      assert task.description == "Test description"
      assert is_binary(task.rank)
      assert task.archived_at == nil
    end

    test "create_task/1 inserts newly created tasks on top", %{user: user} do
      assert {:ok, task1} =
               Tasks.create_task(%{
                 user_id: user.id,
                 title: "Older task"
               })

      assert {:ok, task2} =
               Tasks.create_task(%{
                 user_id: user.id,
                 title: "Newer task"
               })

      tasks = Tasks.list_active_tasks(user.id)

      assert Enum.map(tasks, & &1.id) == [task2.id, task1.id]
    end

    test "list_active_tasks/1 returns only active tasks ordered by rank", %{user: user} do
      assert {:ok, task1} =
               Tasks.create_task(%{
                 user_id: user.id,
                 title: "Task 1"
               })

      assert {:ok, task2} =
               Tasks.create_task(%{
                 user_id: user.id,
                 title: "Task 2"
               })

      {:ok, _archived_task} =
        Tasks.create_task(%{
          user_id: user.id,
          title: "Archived task"
        })
        |> then(fn {:ok, task} -> Tasks.archive_task(task) end)

      tasks = Tasks.list_active_tasks(user.id)

      assert Enum.map(tasks, & &1.id) == [task2.id, task1.id]
      assert Enum.all?(tasks, &is_nil(&1.archived_at))
    end

    test "list_archived_tasks/1 returns only archived tasks", %{user: user} do
      assert {:ok, active_task} =
               Tasks.create_task(%{
                 user_id: user.id,
                 title: "Active task"
               })

      assert {:ok, archived_task} =
               Tasks.create_task(%{
                 user_id: user.id,
                 title: "Archived task"
               })

      assert {:ok, archived_task} = Tasks.archive_task(archived_task)

      tasks = Tasks.list_archived_tasks(user.id)

      assert Enum.map(tasks, & &1.id) == [archived_task.id]
      assert archived_task.archived_at != nil

      refute Enum.any?(tasks, &(&1.id == active_task.id))
    end

    test "get_user_task!/2 returns the user's task", %{user: user} do
      assert {:ok, task} =
               Tasks.create_task(%{
                 user_id: user.id,
                 title: "My task"
               })

      fetched = Tasks.get_user_task!(user.id, task.id)

      assert fetched.id == task.id
    end

    test "get_user_task!/2 does not return another user's task", %{user: user} do
      other_user = AccountsFixtures.user_fixture()

      assert {:ok, task} =
               Tasks.create_task(%{
                 user_id: other_user.id,
                 title: "Other user's task"
               })

      assert_raise Ecto.NoResultsError, fn ->
        Tasks.get_user_task!(user.id, task.id)
      end
    end

    test "update_task/2 updates title and description", %{user: user} do
      assert {:ok, task} =
               Tasks.create_task(%{
                 user_id: user.id,
                 title: "Old title",
                 description: "Old description"
               })

      assert {:ok, updated_task} =
               Tasks.update_task(task, %{
                 title: "New title",
                 description: "New description"
               })

      assert updated_task.title == "New title"
      assert updated_task.description == "New description"
      assert updated_task.rank == task.rank
    end

    test "archive_task/1 sets archived_at", %{user: user} do
      assert {:ok, task} =
               Tasks.create_task(%{
                 user_id: user.id,
                 title: "Task to archive"
               })

      assert task.archived_at == nil

      assert {:ok, archived_task} = Tasks.archive_task(task)
      assert archived_task.archived_at != nil
    end

    test "reorder_task/4 moves a task between neighbors", %{user: user} do
      assert {:ok, task_a} =
               Tasks.create_task(%{
                 user_id: user.id,
                 title: "Task A"
               })

      assert {:ok, task_b} =
               Tasks.create_task(%{
                 user_id: user.id,
                 title: "Task B"
               })

      assert {:ok, task_c} =
               Tasks.create_task(%{
                 user_id: user.id,
                 title: "Task C"
               })

      # Initial top-insert order:
      # [task_c, task_b, task_a]
      assert Enum.map(Tasks.list_active_tasks(user.id), & &1.id) == [
               task_c.id,
               task_b.id,
               task_a.id
             ]

      # Move task_a to the top: before task_c
      assert {:ok, _task_a} = Tasks.reorder_task(user.id, task_a.id, nil, task_c.id)

      assert Enum.map(Tasks.list_active_tasks(user.id), & &1.id) == [
               task_a.id,
               task_c.id,
               task_b.id
             ]
    end

    test "reorder_task/4 returns invalid neighbor error if task is its own neighbor", %{
      user: user
    } do
      assert {:ok, task} =
               Tasks.create_task(%{
                 user_id: user.id,
                 title: "Task"
               })

      assert {:error, :invalid_neighbor} = Tasks.reorder_task(user.id, task.id, task.id, nil)
      assert {:error, :invalid_neighbor} = Tasks.reorder_task(user.id, task.id, nil, task.id)
    end

    test "reorder_task/4 returns not found error when neighbor belongs to another user", %{
      user: user
    } do
      other_user = AccountsFixtures.user_fixture()

      assert {:ok, user_task} =
               Tasks.create_task(%{
                 user_id: user.id,
                 title: "User task"
               })

      assert {:ok, other_task} =
               Tasks.create_task(%{
                 user_id: other_user.id,
                 title: "Other task"
               })

      assert {:error, :not_found} = Tasks.reorder_task(user.id, user_task.id, nil, other_task.id)
    end

    test "create_task/1 returns error for invalid attrs", %{user: user} do
      assert {:error, changeset} =
               Tasks.create_task(%{
                 user_id: user.id,
                 title: ""
               })

      refute changeset.valid?
      assert %{title: ["can't be blank"]} = errors_on(changeset)
    end
  end
end
