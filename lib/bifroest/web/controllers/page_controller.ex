defmodule Bifroest.Web.PageController do
  use Bifroest.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
