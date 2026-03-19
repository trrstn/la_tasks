defmodule LaTasksWeb.API.AuthControllerTest do
  use LaTasksWeb.ConnCase, async: true

  alias LaTasks.Accounts

  describe "POST /api/register" do
    test "registers a user and returns token", %{conn: conn} do
      params = %{
        "user" => %{
          "username" => "tristan-dev",
          "password" => "Password1!",
          "password_confirmation" => "Password1!"
        }
      }

      conn = post(conn, "/api/register", params)
      body = json_response(conn, 201)

      assert body["message"] == "User registered successfully"
      assert body["user"]["username"] == "tristan-dev"
      assert is_binary(body["token"])
    end

    test "returns validation errors for invalid payload", %{conn: conn} do
      params = %{
        "user" => %{
          "username" => "ab",
          "password" => "short",
          "password_confirmation" => "short"
        }
      }

      conn = post(conn, "/api/register", params)
      body = json_response(conn, 422)

      assert body["errors"]["username"] != nil
      assert body["errors"]["password"] != nil
    end

    test "returns bad request when user payload is missing", %{conn: conn} do
      conn = post(conn, "/api/register", %{})
      body = json_response(conn, 400)

      assert body["error"] == "user payload is required"
    end
  end

  describe "POST /api/login" do
    test "logs in and returns token", %{conn: conn} do
      {:ok, _user} =
        Accounts.register_user(%{
          username: "tristan-dev",
          password: "Password1!",
          password_confirmation: "Password1!"
        })

      params = %{
        "user" => %{
          "username" => "tristan-dev",
          "password" => "Password1!"
        }
      }

      conn = post(conn, "/api/login", params)
      body = json_response(conn, 200)

      assert body["message"] == "Login successful"
      assert body["user"]["username"] == "tristan-dev"
      assert is_binary(body["token"])
    end

    test "returns unauthorized for invalid credentials", %{conn: conn} do
      {:ok, _user} =
        Accounts.register_user(%{
          username: "tristan-dev",
          password: "Password1!",
          password_confirmation: "Password1!"
        })

      params = %{
        "user" => %{
          "username" => "tristan-dev",
          "password" => "WrongPassword1!"
        }
      }

      conn = post(conn, "/api/login", params)
      body = json_response(conn, 401)

      assert body["error"] == "Invalid username or password"
    end

    test "returns bad request for malformed payload", %{conn: conn} do
      conn = post(conn, "/api/login", %{})
      body = json_response(conn, 400)

      assert body["error"] == "user.username and user.password are required"
    end
  end

  describe "GET /api/me" do
    test "returns current user when token is valid", %{conn: conn} do
      {:ok, user} =
        Accounts.register_user(%{
          username: "tristan-dev",
          password: "Password1!",
          password_confirmation: "Password1!"
        })

      token = Accounts.create_user_api_token(user)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/me")

      body = json_response(conn, 200)

      assert body["user"]["id"] == user.id
      assert body["user"]["username"] == user.username
    end

    test "returns unauthorized when token is missing", %{conn: conn} do
      conn = get(conn, "/api/me")
      body = json_response(conn, 401)

      assert body["error"] == "Unauthorized"
    end

    test "returns unauthorized when token is invalid", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer invalid-token")
        |> get("/api/me")

      body = json_response(conn, 401)

      assert body["error"] == "Unauthorized"
    end
  end

  describe "DELETE /api/logout" do
    test "revokes token", %{conn: conn} do
      {:ok, user} =
        Accounts.register_user(%{
          username: "tristan-dev",
          password: "Password1!",
          password_confirmation: "Password1!"
        })

      token = Accounts.create_user_api_token(user)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> delete("/api/logout")

      body = json_response(conn, 200)

      assert body["message"] == "Logged out successfully"

      conn =
        build_conn()
        |> put_req_header("accept", "application/json")
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/me")

      body = json_response(conn, 401)
      assert body["error"] == "Unauthorized"
    end

    test "returns bad request when authorization header is missing", %{conn: conn} do
      conn = delete(conn, "/api/logout")
      body = json_response(conn, 400)

      assert body["error"] == "Authorization header is required"
    end
  end
end
