defmodule LaTasks.Accounts.UserToken do
  use Ecto.Schema
  import Ecto.Changeset

  alias LaTasks.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "users_tokens" do
    field :access_key, :binary
    field :expires_at, :utc_datetime

    belongs_to :user, User

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(user_token, attrs) do
    user_token
    |> cast(attrs, [:access_key, :expires_at, :user_id])
    |> validate_required([:access_key, :user_id])
    |> unique_constraint(:access_key)
    |> foreign_key_constraint(:user_id)
  end
end
