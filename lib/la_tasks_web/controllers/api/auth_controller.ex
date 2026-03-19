defmodule LaTasksWeb.API.AuthController do
  use LaTasksWeb, :controller

  alias LaTasks.Accounts

  def register(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        token = Accounts.create_user_api_token(user)

        conn
        |> put_status(:created)
        |> json(%{
          message: "User registered successfully",
          user: %{
            id: user.id,
            username: user.username
          },
          token: token
        })

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: translate_errors(changeset)})
    end
  end

  def register(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "user payload is required"})
  end

  def login(conn, %{"user" => %{"username" => username, "password" => password}}) do
    case Accounts.authenticate_user(username, password) do
      {:ok, user} ->
        token = Accounts.create_user_api_token(user)

        conn
        |> put_status(:ok)
        |> json(%{
          message: "Login successful",
          user: %{
            id: user.id,
            username: user.username
          },
          token: token
        })

      {:error, :invalid_credentials} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid username or password"})
    end
  end

  def login(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "user.username and user.password are required"})
  end

  def logout(conn, _params) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] ->
        _ = Accounts.revoke_user_api_token(token)

        conn
        |> put_status(:ok)
        |> json(%{message: "Logged out successfully"})

      _ ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Authorization header is required"})
    end
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
