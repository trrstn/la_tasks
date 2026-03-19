defmodule LaTasksWeb.API.TaskController do
  use LaTasksWeb, :controller

  alias LaTasks.Tasks

  def index(conn, _params) do
    current_user = conn.assigns.current_user
    tasks = Tasks.list_active_tasks(current_user.id)

    conn
    |> put_status(:ok)
    |> json(%{
      data: Enum.map(tasks, &serialize_task/1)
    })
  end

  def create(conn, params) do
    current_user = conn.assigns.current_user

    attrs = %{
      "title" => params["title"],
      "description" => params["description"],
      "user_id" => current_user.id
    }

    case Tasks.create_task(attrs) do
      {:ok, task} ->
        conn
        |> put_status(:created)
        |> json(%{
          message: "Task created successfully",
          task: serialize_task(task)
        })

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: translate_errors(changeset)})
    end
  end

  def update(conn, %{"id" => id} = params) do
    current_user = conn.assigns.current_user

    with {:ok, task} <- Tasks.get_user_task(current_user.id, id),
         {:ok, updated_task} <-
           Tasks.update_task(task, %{
             "title" => params["title"],
             "description" => params["description"]
           }) do
      conn
      |> put_status(:ok)
      |> json(%{
        message: "Task updated successfully",
        task: serialize_task(updated_task)
      })
    else
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Task not found"})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: translate_errors(changeset)})
    end
  end

  def archive(conn, %{"id" => id}) do
    current_user = conn.assigns.current_user

    with {:ok, task} <- Tasks.get_user_task(current_user.id, id),
         {:ok, archived_task} <- Tasks.archive_task(task) do
      conn
      |> put_status(:ok)
      |> json(%{
        message: "Task archived successfully",
        task: serialize_task(archived_task)
      })
    else
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Task not found"})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: translate_errors(changeset)})
    end
  end

  def reorder(conn, %{"task_id" => task_id} = params) do
    current_user = conn.assigns.current_user
    prev_id = blank_to_nil(params["prev_id"])
    next_id = blank_to_nil(params["next_id"])

    with :ok <- validate_reorder_params(prev_id, next_id),
         {:ok, reordered_task} <-
           Tasks.reorder_task(current_user.id, task_id, prev_id, next_id) do
      conn
      |> put_status(:ok)
      |> json(%{
        message: "Task reordered successfully",
        task: serialize_task(reordered_task)
      })
    else
      {:error, :invalid_reorder_position} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "prev_id and next_id cannot both be empty"})

      {:error, :duplicate_neighbors} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "prev_id and next_id cannot be the same"})

      {:error, :invalid_neighbor} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Task cannot be its own neighbor"})

      {:error, :invalid_neighbor_order} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Invalid neighbor order"})

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Task not found"})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: translate_errors(changeset)})
    end
  end

  defp validate_reorder_params(nil, nil), do: {:error, :invalid_reorder_position}

  defp validate_reorder_params(prev_id, next_id) when prev_id == next_id and not is_nil(prev_id),
    do: {:error, :duplicate_neighbors}

  defp validate_reorder_params(_, _), do: :ok

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value

  defp serialize_task(task) do
    %{
      id: task.id,
      title: task.title,
      description: task.description,
      rank: task.rank,
      archived_at: task.archived_at,
      user_id: task.user_id,
      inserted_at: task.inserted_at,
      updated_at: task.updated_at
    }
  end

  defp translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts
        |> Keyword.get(String.to_existing_atom(key), key)
        |> to_string()
      end)
    end)
  end
end
