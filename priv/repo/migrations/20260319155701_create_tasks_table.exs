defmodule LaTasks.Repo.Migrations.CreateTasksTable do
  use Ecto.Migration

  def change do
    create table(:tasks) do
      add :title, :string, null: false
      add :rank, :string, null: false
      add :description, :text
      add :archived_at, :utc_datetime

      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:tasks, [:user_id])
    create index(:tasks, [:user_id, :archived_at, :rank])
  end
end
