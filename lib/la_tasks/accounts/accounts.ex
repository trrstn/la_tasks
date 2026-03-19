defmodule LaTasks.Accounts do
  @moduledoc """
  The Accounts context.

  Handles user registration, authentication, and account-related operations.
  """

  import Ecto.Query

  alias LaTasks.Accounts.{User, UserToken}
  alias LaTasks.Repo

  @token_size 32
  @token_ttl_days 30

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

  def create_user_api_token(user) do
    raw_token = :crypto.strong_rand_bytes(@token_size)
    hashed_token = :crypto.hash(:sha256, raw_token)

    expires_at =
      DateTime.add(DateTime.utc_now(), @token_ttl_days * 24 * 60 * 60, :second)

    %UserToken{}
    |> UserToken.changeset(%{
      access_key: hashed_token,
      user_id: user.id,
      expires_at: expires_at
    })
    |> Repo.insert!()

    Base.url_encode64(raw_token, padding: false)
  end

  def fetch_user_by_api_token(token) when is_binary(token) do
    with {:ok, decoded} <- Base.url_decode64(token, padding: false),
         hashed <- :crypto.hash(:sha256, decoded),
         %User{} = user <-
           Repo.one(
             from t in UserToken,
               join: u in assoc(t, :user),
               where:
                 t.access_key == ^hashed and
                   t.expires_at > ^DateTime.utc_now(),
               select: u
           ) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  def revoke_user_api_token(token) when is_binary(token) do
    with {:ok, decoded_token} <- Base.url_decode64(token, padding: false),
         hashed_token <- :crypto.hash(:sha256, decoded_token) do
      from(t in UserToken, where: t.access_key == ^hashed_token)
      |> Repo.delete_all()

      :ok
    else
      _ -> :error
    end
  end
end
