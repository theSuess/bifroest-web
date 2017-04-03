defmodule Bifroest.Web.Router do
  use Bifroest.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Guardian.Plug.VerifySession
    plug Guardian.Plug.LoadResource
    plug Bifroest.Web.Locale
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug Guardian.Plug.VerifySession
    plug Guardian.Plug.LoadResource
  end

  pipeline :api_auth do
    plug Guardian.Plug.EnsureAuthenticated, handler: Bifroest.Web.APIAuthController
  end

  pipeline :browser_auth do
    plug Guardian.Plug.EnsureAuthenticated, handler: Bifroest.Web.AuthController
  end

  pipeline :browser_admin do
    plug Guardian.Plug.EnsurePermissions, handler: Bifroest.Web.AuthController, default: [:admin]
  end

  scope "/", Bifroest.Web do
    pipe_through [:browser,:browser_auth] # Use the default browser stack

    get "/", PageController, :index
  end

  scope "/auth", Bifroest.Web do
    pipe_through :browser

    get "/", AuthController, :index
    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
    post "/:provider/callback", AuthController, :callback
    delete "/", AuthController, :delete
  end

  scope "/admin", Bifroest.Web do
    pipe_through [:browser, :browser_auth, :browser_admin]
    get "/", PageController, :admin
  end

  # Other scopes may use custom stacks.
  scope "/api", Bifroest.Web do
    pipe_through [:api,:api_auth]
    resources "/domains", DomainController, except: [:new, :edit]
  end
end
