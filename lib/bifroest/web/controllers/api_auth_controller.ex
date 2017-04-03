defmodule Bifroest.Web.APIAuthController do
  use Bifroest.Web, :controller
  plug :put_view, Bifroest.Web.APIAuthView
  def unauthenticated(conn, _params) do
    send_resp(conn, :unauthorized, "")
  end

  def unauthorized(conn, _params) do
    send_resp(conn, :forbidden, "")
  end
end
