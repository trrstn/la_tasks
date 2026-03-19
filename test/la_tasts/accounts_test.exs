defmodule LaTasks.AccountsTest do
  use LaTasks.DataCase, async: true

  alias LaTasks.Accounts
  alias LaTasks.Accounts.User

  describe "create/1" do
    test "creates a user with valid attributes" do
      attrs = %{
        username: "tristan_123",
        password: "Password1!",
        password_confirmation: "Password1!"
      }

      assert {:ok, %User{} = user} = Accounts.create(attrs)
      assert user.username == "tristan_123"
      assert user.hashed_password
      refute user.hashed_password == "Password1!"
    end

    test "fails when username is missing" do
      attrs = %{
        password: "Password1!",
        password_confirmation: "Password1!"
      }

      assert {:error, changeset} = Accounts.create(attrs)

      assert "can't be blank" in errors_on(changeset).username
    end

    test "fails when username is too short" do
      attrs = %{
        username: "ab",
        password: "Password1!",
        password_confirmation: "Password1!"
      }

      assert {:error, changeset} = Accounts.create(attrs)

      assert "should be at least 3 character(s)" in errors_on(changeset).username
    end

    test "fails when username has invalid characters" do
      attrs = %{
        username: "tristan!",
        password: "Password1!",
        password_confirmation: "Password1!"
      }

      assert {:error, changeset} = Accounts.create(attrs)

      assert "has invalid format" in errors_on(changeset).username
    end

    test "fails when username is already taken" do
      attrs = %{
        username: "tristan_123",
        password: "Password1!",
        password_confirmation: "Password1!"
      }

      assert {:ok, _user} = Accounts.create(attrs)
      assert {:error, changeset} = Accounts.create(attrs)

      assert "has already been taken" in errors_on(changeset).username
    end

    test "fails when password is too short" do
      attrs = %{
        username: "tristan_123",
        password: "Pass1!",
        password_confirmation: "Pass1!"
      }

      assert {:error, changeset} = Accounts.create(attrs)

      assert "password should be at least 8 characters" in errors_on(changeset).password
    end

    test "fails when password has no special character" do
      attrs = %{
        username: "tristan_123",
        password: "Password1",
        password_confirmation: "Password1"
      }

      assert {:error, changeset} = Accounts.create(attrs)

      assert "password must contain at least one special character" in errors_on(changeset).password
    end

    test "fails when password has no uppercase letter" do
      attrs = %{
        username: "tristan_123",
        password: "password1!",
        password_confirmation: "password1!"
      }

      assert {:error, changeset} = Accounts.create(attrs)

      assert "password must contain an uppercase letter" in errors_on(changeset).password
    end

    test "fails when password confirmation does not match" do
      attrs = %{
        username: "tristan_123",
        password: "Password1!",
        password_confirmation: "Password2!"
      }

      assert {:error, changeset} = Accounts.create(attrs)

      assert "does not match confirmation" in errors_on(changeset).password_confirmation
    end
  end
end
