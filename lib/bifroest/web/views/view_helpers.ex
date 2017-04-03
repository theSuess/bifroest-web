defmodule Bifroest.Web.ViewHelpers do
  def current_user(conn), do: Guardian.Plug.current_resource(conn)
  def logged_in?(conn), do: Guardian.Plug.authenticated?(conn)
  def organization_name(), do: Application.get_env(:bifroest,:organization_name)
  def domain_base(), do: Application.get_env(:bifroest,:domain_base)
  def domains(conn) do
    user = current_user(conn)
    Bifroest.Loadbalancer.list_domains(user)
  end
  def all_domains() do
    Bifroest.Loadbalancer.list_domains() |> Bifroest.Repo.preload(:user)
  end
end
