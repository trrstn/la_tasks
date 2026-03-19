defmodule LaTasks.Accounts do
  @moduledoc """
    The Accounts context.
    
    Handles user registration, authentication, and account-related operations.
  """
  alias LaTasks.Accounts.User
  alias LaTasks.Repo
  import Ecto.Changeset

  ## Mutations
  def create(attrs) do
    %User{}
    |> create_changeset(attrs)
    |> Repo.insert()
  end

  ## Changesets and utils
  defp create_changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :password, :password_confirmation])
    |> validate_required([:username, :password, :password_confirmation])
    |> validate_length(:username, min: 3, max: 20)
    |> validate_format(:username, ~r/^[a-zA-Z0-9_]+$/)
    |> unique_constraint(:username)
    |> validate_password()
    |> put_password_hash()
  end

  defp validate_password(changeset) do
    changeset
    |> validate_length(:password, min: 8, message: "password should be at least 8 characters")
    |> validate_format(:password, ~r/[[:punct:]]/,
      message: "password must contain at least one special character"
    )
    |> validate_format(:password, ~r/[A-Z]+/,
      message: "password must contain an uppercase letter"
    )
    |> validate_confirmation(:password)
  end

  defp put_password_hash(%Ecto.Changeset{valid?: true} = changeset) do
    case get_change(changeset, :password) do
      nil ->
        changeset

      password ->
        hash = Argon2.hash_pwd_salt(password)
        put_change(changeset, :hashed_password, hash)
    end
  end

  defp put_password_hash(changeset), do: changeset
end
