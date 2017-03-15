defmodule Bifroest.Web.AuthController do
  use Bifroest.Web, :controller
  alias Bifroest.Accounts
  plug Ueberauth

  alias Ueberauth.Strategy.Helpers
  def request(conn, _params) do
    render(conn, "request.html", callback_url: Helpers.callback_url(conn))
  end

  def index(conn, _params) do
    if Guardian.Plug.authenticated? conn do
      conn
      |> put_flash(:info, "You are allready authenticated")
      |> redirect(to: page_path(conn,:index))
    else
      conn
      |> put_layout("login.html")
      |> render("login.html")
    end
  end

  def delete(conn, _params) do
    conn
    |> Guardian.Plug.sign_out
    |> put_flash(:info, "You have been logged out!")
    |> redirect(to: auth_path(conn, :index))
  end

  def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    conn
    |> put_flash(:error, "Failed to authenticate.")
    |> redirect(to: auth_path(conn, :index))
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    case Accounts.find_or_create(auth) do
      {:ok, user} ->
        conn
        |> Guardian.Plug.sign_in(user)
        |> put_flash(:info, "Successfully authenticated.")
        |> redirect(to: page_path(conn, :index))
      {:error, reason} ->
        conn
        |> put_flash(:error, reason)
        |> redirect(to: auth_path(conn, :index))
    end
  end

  def unauthenticated(conn, _params) do
    conn
    |> put_flash(:error, "You must be signed in to access this page")
    |> redirect(to: auth_path(conn, :index))
  end

  def unauthorized(conn, _params) do
    conn
    |> put_flash(:error, "You are not authorized to view this page")
    |> redirect(to: auth_path(conn, :index))
  end
end
