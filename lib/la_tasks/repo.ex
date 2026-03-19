defmodule LaTasks.Repo do
  use Ecto.Repo,
    otp_app: :la_tasks,
    adapter: Ecto.Adapters.Postgres
end
