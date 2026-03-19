defmodule LaTasksWeb.Router do
  use LaTasksWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {LaTasksWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :api_auth do
    plug LaTasksWeb.Plugs.APIAuth
  end

  scope "/", LaTasksWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  scope "/api", LaTasksWeb.API do
    pipe_through :api

    post "/register", AuthController, :register
    post "/login", AuthController, :login
    delete "/logout", AuthController, :logout
  end

  scope "/api", LaTasksWeb.API do
    pipe_through [:api, :api_auth]

    get "/tasks", TaskController, :index
    post "/tasks", TaskController, :create
    patch "/tasks/reorder", TaskController, :reorder
    patch "/tasks/:id/archive", TaskController, :archive
    patch "/tasks/:id", TaskController, :update
  end

  # Other scopes may use custom stacks.
  # scope "/api", LaTasksWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:la_tasks, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: LaTasksWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
