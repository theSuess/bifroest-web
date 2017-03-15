defmodule Bifroest.Web.ViewHelpers do
  def current_user(conn), do: Guardian.Plug.current_resource(conn)
  def logged_in?(conn), do: Guardian.Plug.authenticated?(conn)
  def organization_name(), do: Application.get_env(:bifroest,:organization_name)
end
