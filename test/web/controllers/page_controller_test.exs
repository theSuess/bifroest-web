defmodule Bifroest.Web.PageControllerTest do
  use Bifroest.Web.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 302) == "<html><body>You are being <a href=\"/auth\">redirected</a>.</body></html>"
  end
end
