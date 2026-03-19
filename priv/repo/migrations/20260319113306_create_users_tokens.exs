defmodule LaTasks.Repo.Migrations.CreateUsersTokens do
  use Ecto.Migration

  def change do
    create table(:users_tokens) do
      add :expires_at, :utc_datetime
      add :access_key, :binary
      add :user_id, references(:users)

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:users_tokens, [:user_id])
    create index(:users_tokens, [:expires_at])
    create unique_index(:users_tokens, [:access_key])
  end
end
