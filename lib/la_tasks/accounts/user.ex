defmodule LaTasks.Accounts.User do
  use Ecto.Schema

  schema "users" do
    field :username, :string
    field :hashed_password, :string, redact: true
    field :password, :string, virtual: true, redact: true
    field :password_confirmation, :string, virtual: true, redact: true

    timestamps(type: :utc_datetime)
  end
end
