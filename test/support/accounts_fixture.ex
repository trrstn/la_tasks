defmodule LaTasks.AccountsFixtures do
  @moduledoc """
  Test helpers for creating users.
  """

  alias LaTasks.Accounts

  def unique_username do
    id =
      System.unique_integer([:positive])
      |> Integer.to_string()
      |> String.slice(-8..-1)

    "user-#{id}"
  end

  def valid_user_password do
    "Password1!"
  end

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      username: unique_username(),
      password: valid_user_password(),
      password_confirmation: valid_user_password()
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Accounts.register_user()

    user
  end
end
