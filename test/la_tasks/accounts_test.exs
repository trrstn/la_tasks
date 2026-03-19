defmodule LaTasks.AccountsTest do
  use LaTasks.DataCase, async: true

  alias LaTasks.Accounts
  alias LaTasks.Accounts.{User, UserToken}

  describe "register_user/1" do
    test "creates a user with valid attributes" do
      attrs = %{
        username: "tristan-dev",
        password: "Password1!",
        password_confirmation: "Password1!"
      }

      assert {:ok, %User{} = user} = Accounts.register_user(attrs)
      assert user.username == "tristan-dev"
      assert user.hashed_password
      refute user.hashed_password == "Password1!"
    end

    test "normalizes username by trimming and downcasing" do
      attrs = %{
        username: "  Tristan-Dev  ",
        password: "Password1!",
        password_confirmation: "Password1!"
      }

      assert {:ok, %User{} = user} = Accounts.register_user(attrs)
      assert user.username == "tristan-dev"
    end

    test "fails when username is missing" do
      attrs = %{
        password: "Password1!",
        password_confirmation: "Password1!"
      }

      assert {:error, changeset} = Accounts.register_user(attrs)

      assert "can't be blank" in errors_on(changeset).username
    end

    test "fails when password is missing" do
      attrs = %{
        username: "tristan-dev",
        password_confirmation: "Password1!"
      }

      assert {:error, changeset} = Accounts.register_user(attrs)

      assert "can't be blank" in errors_on(changeset).password
    end

    test "fails when password confirmation is missing" do
      attrs = %{
        username: "tristan-dev",
        password: "Password1!"
      }

      assert {:error, changeset} = Accounts.register_user(attrs)

      assert "can't be blank" in errors_on(changeset).password_confirmation
    end

    test "fails when username is too short" do
      attrs = %{
        username: "ab",
        password: "Password1!",
        password_confirmation: "Password1!"
      }

      assert {:error, changeset} = Accounts.register_user(attrs)

      assert "should be at least 3 character(s)" in errors_on(changeset).username
    end

    test "fails when username is too long" do
      attrs = %{
        username: String.duplicate("a", 21),
        password: "Password1!",
        password_confirmation: "Password1!"
      }

      assert {:error, changeset} = Accounts.register_user(attrs)

      assert "should be at most 20 character(s)" in errors_on(changeset).username
    end

    test "fails when username contains underscores" do
      attrs = %{
        username: "tristan_dev",
        password: "Password1!",
        password_confirmation: "Password1!"
      }

      assert {:error, changeset} = Accounts.register_user(attrs)

      assert "must contain only lowercase letters, numbers, and single hyphens; it cannot start or end with a hyphen" in errors_on(
               changeset
             ).username
    end

    test "fails when username contains uppercase-only invalid pattern after normalization" do
      attrs = %{
        username: "Tristan_Dev",
        password: "Password1!",
        password_confirmation: "Password1!"
      }

      assert {:error, changeset} = Accounts.register_user(attrs)

      assert "must contain only lowercase letters, numbers, and single hyphens; it cannot start or end with a hyphen" in errors_on(
               changeset
             ).username
    end

    test "fails when username starts with a hyphen" do
      attrs = %{
        username: "-tristan",
        password: "Password1!",
        password_confirmation: "Password1!"
      }

      assert {:error, changeset} = Accounts.register_user(attrs)

      assert "must contain only lowercase letters, numbers, and single hyphens; it cannot start or end with a hyphen" in errors_on(
               changeset
             ).username
    end

    test "fails when username ends with a hyphen" do
      attrs = %{
        username: "tristan-",
        password: "Password1!",
        password_confirmation: "Password1!"
      }

      assert {:error, changeset} = Accounts.register_user(attrs)

      assert "must contain only lowercase letters, numbers, and single hyphens; it cannot start or end with a hyphen" in errors_on(
               changeset
             ).username
    end

    test "fails when username has consecutive hyphens" do
      attrs = %{
        username: "tristan--dev",
        password: "Password1!",
        password_confirmation: "Password1!"
      }

      assert {:error, changeset} = Accounts.register_user(attrs)

      assert "must contain only lowercase letters, numbers, and single hyphens; it cannot start or end with a hyphen" in errors_on(
               changeset
             ).username
    end

    test "fails when username is already taken" do
      attrs = %{
        username: "tristan-dev",
        password: "Password1!",
        password_confirmation: "Password1!"
      }

      assert {:ok, _user} = Accounts.register_user(attrs)
      assert {:error, changeset} = Accounts.register_user(attrs)

      assert "username has already been taken" in errors_on(changeset).username
    end

    test "fails when password is too short" do
      attrs = %{
        username: "tristan-dev",
        password: "Pass1!",
        password_confirmation: "Pass1!"
      }

      assert {:error, changeset} = Accounts.register_user(attrs)

      assert "password should be at least 8 characters" in errors_on(changeset).password
    end

    test "fails when password has no special character" do
      attrs = %{
        username: "tristan-dev",
        password: "Password1",
        password_confirmation: "Password1"
      }

      assert {:error, changeset} = Accounts.register_user(attrs)

      assert "password must contain at least one special character" in errors_on(changeset).password
    end

    test "fails when password has no uppercase letter" do
      attrs = %{
        username: "tristan-dev",
        password: "password1!",
        password_confirmation: "password1!"
      }

      assert {:error, changeset} = Accounts.register_user(attrs)

      assert "password must contain an uppercase letter" in errors_on(changeset).password
    end

    test "fails when password confirmation does not match" do
      attrs = %{
        username: "tristan-dev",
        password: "Password1!",
        password_confirmation: "Password2!"
      }

      assert {:error, changeset} = Accounts.register_user(attrs)

      assert "does not match confirmation" in errors_on(changeset).password_confirmation
    end
  end

  describe "authenticate_user/2" do
    test "returns user for valid credentials" do
      {:ok, user} =
        Accounts.register_user(%{
          username: "tristan-dev",
          password: "Password1!",
          password_confirmation: "Password1!"
        })

      assert {:ok, authenticated_user} = Accounts.authenticate_user("tristan-dev", "Password1!")
      assert authenticated_user.id == user.id
      assert authenticated_user.username == user.username
    end

    test "returns error for invalid password" do
      {:ok, _user} =
        Accounts.register_user(%{
          username: "tristan-dev",
          password: "Password1!",
          password_confirmation: "Password1!"
        })

      assert {:error, :invalid_credentials} =
               Accounts.authenticate_user("tristan-dev", "WrongPassword1!")
    end

    test "normalizes username during authentication" do
      {:ok, user} =
        Accounts.register_user(%{
          username: "tristan-dev",
          password: "Password1!",
          password_confirmation: "Password1!"
        })

      assert {:ok, authenticated_user} = Accounts.authenticate_user("tristan-dev", "Password1!")
      assert authenticated_user.id == user.id
      assert authenticated_user.username == user.username
    end
  end

  describe "api tokens" do
    test "create_user_api_token/1 stores hashed token and returns raw token" do
      {:ok, user} =
        Accounts.register_user(%{
          username: "tristan-dev",
          password: "Password1!",
          password_confirmation: "Password1!"
        })

      token = Accounts.create_user_api_token(user)

      assert is_binary(token)

      token_row =
        Repo.one!(
          from t in UserToken,
            where: t.user_id == ^user.id
        )

      refute token_row.access_key == token
      assert is_binary(token_row.access_key)
      assert %DateTime{} = token_row.expires_at
    end

    test "fetch_user_by_api_token/1 returns user for valid token" do
      {:ok, user} =
        Accounts.register_user(%{
          username: "tristan-dev",
          password: "Password1!",
          password_confirmation: "Password1!"
        })

      token = Accounts.create_user_api_token(user)

      assert {:ok, fetched_user} = Accounts.fetch_user_by_api_token(token)
      assert fetched_user.id == user.id
    end

    test "fetch_user_by_api_token/1 returns error for invalid token" do
      assert :error = Accounts.fetch_user_by_api_token("not-a-real-token")
    end

    test "fetch_user_by_api_token/1 returns error for expired token" do
      {:ok, user} =
        Accounts.register_user(%{
          username: "tristan-dev",
          password: "Password1!",
          password_confirmation: "Password1!"
        })

      raw_token = :crypto.strong_rand_bytes(32)
      encoded_token = Base.url_encode64(raw_token, padding: false)
      hashed_token = :crypto.hash(:sha256, raw_token)

      expired_at = DateTime.add(DateTime.utc_now(), -3600, :second)

      %UserToken{}
      |> UserToken.changeset(%{
        access_key: hashed_token,
        expires_at: expired_at,
        user_id: user.id
      })
      |> Repo.insert!()

      assert :error = Accounts.fetch_user_by_api_token(encoded_token)
    end

    test "revoke_user_api_token/1 deletes the token" do
      {:ok, user} =
        Accounts.register_user(%{
          username: "tristan-dev",
          password: "Password1!",
          password_confirmation: "Password1!"
        })

      token = Accounts.create_user_api_token(user)

      assert :ok = Accounts.revoke_user_api_token(token)
      assert :error = Accounts.fetch_user_by_api_token(token)
    end
  end
end
