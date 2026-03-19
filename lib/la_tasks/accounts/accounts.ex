defmodule LaTasks.Accounts do
  @moduledoc """
  The Accounts context.

  Handles user registration, authentication, and account-related operations.
  """
  alias LaTasks.Accounts.User
  alias LaTasks.Repo

  ## Mutations
  def register_user(attrs) do
    %User{}
    |> User.create_changeset(attrs)
    |> Repo.insert()
  end

  # Queries
  def get_user_by_username(username) when is_binary(username) do
    username = User.normalize_username(username)
    Repo.get_by(User, username: username)
  end

  ## Utils
  def authenticate_user(username, password)
      when is_binary(username) and is_binary(password) do
    case get_user_by_username(username) do
      nil ->
        Argon2.no_user_verify()
        {:error, :invalid_credentials}

      user ->
        if Argon2.verify_pass(password, user.hashed_password) do
          {:ok, user}
        else
          {:error, :invalid_credentials}
        end
    end
  end
end
