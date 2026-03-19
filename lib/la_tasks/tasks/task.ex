defmodule LaTasks.Tasks.Task do
  use Ecto.Schema
  import Ecto.Changeset

  alias LaTasks.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "tasks" do
    field :title, :string
    field :description, :string
    field :rank, :decimal
    field :archived_at, :utc_datetime

    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  def create_changeset(task, attrs) do
    task
    |> cast(attrs, [:title, :description, :rank, :user_id])
    |> validate_required([:title, :rank, :user_id])
    |> validate_length(:title, min: 1, max: 255)
    |> foreign_key_constraint(:user_id)
  end

  def update_changeset(task, attrs) do
    task
    |> cast(attrs, [:title, :description])
    |> validate_required([:title])
    |> validate_length(:title, min: 1, max: 255)
  end

  def archive_changeset(task, attrs) do
    cast(task, attrs, [:archived_at, :rank])
  end

  def reorder_changeset(task, attrs) do
    task
    |> cast(attrs, [:rank])
    |> validate_required([:rank])
  end
end
