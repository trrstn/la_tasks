defmodule LaTasks.Tasks do
  import Ecto.Query

  alias LaTasks.Repo
  alias LaTasks.Tasks.{Task, Rank}

  def list_active_tasks(user_id) do
    from(t in Task,
      where: t.user_id == ^user_id and is_nil(t.archived_at),
      order_by: [asc: t.rank]
    )
    |> Repo.all()
  end

  def list_archived_tasks(user_id) do
    from(t in Task,
      where: t.user_id == ^user_id and not is_nil(t.archived_at),
      order_by: [desc: t.archived_at]
    )
    |> Repo.all()
  end

  def get_user_task!(user_id, task_id) do
    Repo.one!(
      from t in Task,
        where: t.id == ^task_id and t.user_id == ^user_id
    )
  end

  def get_user_task(user_id, task_id) do
    case Repo.one(
           from t in Task,
             where: t.id == ^task_id and t.user_id == ^user_id
         ) do
      nil -> {:error, :not_found}
      task -> {:ok, task}
    end
  end

  def create_task(attrs) when is_map(attrs) do
    attrs = normalize_attrs(attrs)
    user_id = Map.fetch!(attrs, :user_id)

    first_rank = first_active_rank(user_id)
    new_rank = Rank.between(nil, first_rank)

    attrs = Map.put(attrs, :rank, new_rank)

    %Task{}
    |> Task.create_changeset(attrs)
    |> Repo.insert()
  end

  def update_task(%Task{} = task, attrs) do
    attrs = normalize_attrs(attrs)

    task
    |> Task.update_changeset(attrs)
    |> Repo.update()
  end

  def archive_task(%Task{} = task) do
    task
    |> Task.archive_changeset(%{archived_at: DateTime.utc_now()})
    |> Repo.update()
  end

  def reorder_task(user_id, task_id, prev_id, next_id) do
    Repo.transaction(fn ->
      with {:ok, task} <- get_active_task(user_id, task_id),
           {:ok, prev_rank} <- get_active_rank(user_id, prev_id),
           {:ok, next_rank} <- get_active_rank(user_id, next_id),
           :ok <- validate_neighbors(task.id, prev_id, next_id, prev_rank, next_rank),
           {:ok, task} <- update_task_rank(task, prev_rank, next_rank) do
        task
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  defp first_active_rank(user_id) do
    from(t in Task,
      where: t.user_id == ^user_id and is_nil(t.archived_at),
      order_by: [asc: t.rank],
      limit: 1,
      select: t.rank
    )
    |> Repo.one()
  end

  defp get_active_task(user_id, task_id) do
    case Repo.one(
           from t in Task,
             where:
               t.id == ^task_id and
                 t.user_id == ^user_id and
                 is_nil(t.archived_at),
             lock: "FOR UPDATE"
         ) do
      nil -> {:error, :not_found}
      task -> {:ok, task}
    end
  end

  defp get_active_rank(_user_id, nil), do: {:ok, nil}

  defp get_active_rank(user_id, task_id) do
    case Repo.one(
           from t in Task,
             where:
               t.id == ^task_id and
                 t.user_id == ^user_id and
                 is_nil(t.archived_at),
             select: t.rank
         ) do
      nil -> {:error, :not_found}
      rank -> {:ok, rank}
    end
  end

  defp validate_neighbors(task_id, prev_id, next_id, prev_rank, next_rank) do
    cond do
      task_id == prev_id or task_id == next_id ->
        {:error, :invalid_neighbor}

      prev_id != nil and next_id != nil and prev_rank >= next_rank ->
        {:error, :invalid_neighbor_order}

      true ->
        :ok
    end
  end

  defp update_task_rank(task, prev_rank, next_rank) do
    new_rank = Rank.between(prev_rank, next_rank)

    task
    |> Task.reorder_changeset(%{rank: new_rank})
    |> Repo.update()
  end

  defp normalize_attrs(attrs) when is_map(attrs) do
    Enum.reduce(attrs, %{}, fn
      {key, value}, acc when is_binary(key) ->
        Map.put(acc, String.to_existing_atom(key), value)

      {key, value}, acc ->
        Map.put(acc, key, value)
    end)
  end
end
