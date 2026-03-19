defmodule LaTasks.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      LaTasksWeb.Telemetry,
      LaTasks.Repo,
      {DNSCluster, query: Application.get_env(:la_tasks, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: LaTasks.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: LaTasks.Finch},
      # Start a worker by calling: LaTasks.Worker.start_link(arg)
      # {LaTasks.Worker, arg},
      # Start to serve requests, typically the last entry
      LaTasksWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LaTasks.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LaTasksWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
