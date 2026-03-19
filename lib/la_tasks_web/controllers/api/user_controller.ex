defmodule LaTasksWeb.API.UserController do
  use LaTasksWeb, :controller

  def me(conn, _params) do
    user = conn.assigns.current_user

    json(conn, %{
      user: %{
        id: user.id,
        username: user.username
      }
    })
  end
end
