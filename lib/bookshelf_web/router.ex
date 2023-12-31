defmodule BookshelfWeb.Router do
  require Logger
  use BookshelfWeb, :router

  defp auth(conn, _opts) do
    basic_auth = Application.get_env(:bookshelf, :basic_auth)

    if basic_auth[:enabled] do
      Plug.BasicAuth.basic_auth(conn,
        username: basic_auth[:username],
        password: basic_auth[:password]
      )
    else
      conn
    end
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {BookshelfWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :auth
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", BookshelfWeb do
    pipe_through :browser

    live "/", LiveBooks, :index, as: :live_books

    resources "/books", BookController do
      get "/download", BookController, :download, as: :download
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", BookshelfWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: BookshelfWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
