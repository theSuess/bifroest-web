defmodule Bifroest.Web.PageController do
  use Bifroest.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

  def admin(conn, _params) do
    render conn, "admin.html"
  end

  def lobby(conn, _params) do
    {:ok, claims} = Guardian.Plug.claims(conn)
    if Guardian.Permissions.from_claims(claims) != 0 do
      conn
      |> redirect(to: page_path(conn,:index))
    else
      render conn, "lobby.html"
    end
  end
end
