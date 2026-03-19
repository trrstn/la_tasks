defmodule LaTasks.AccountsTest do
  use LaTasks.DataCase, async: true

  alias LaTasks.Accounts
  alias LaTasks.Accounts.User

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
end
