defmodule Bifroest.Web.ViewHelpers do
  alias Bifroest.Openstack.Compute.Flavor
  def current_user(conn), do: Guardian.Plug.current_resource(conn)
  def logged_in?(conn), do: Guardian.Plug.authenticated?(conn)
  def organization_name(), do: Application.get_env(:bifroest,:organization_name)
  def domain_base(), do: Application.get_env(:bifroest,:domain_base)

  def domains(conn) do
    user = current_user(conn)
    Bifroest.Loadbalancer.list_domains(user) |> Bifroest.Repo.preload(:user)
  end

  def all_domains() do
    Bifroest.Loadbalancer.list_domains() |> Bifroest.Repo.preload(:user)
  end

  def all_users() do
    Bifroest.Accounts.list_users()
  end

  def flavors() do
    {:ok, flavs} = Bifroest.Openstack.Compute.get_flavors()
    Enum.sort(flavs,fn %Flavor{name: n}, %Flavor{name: n2} -> n <= n2 end)
  end

  def images() do
    {:ok, images} = Bifroest.Openstack.Image.get_images()
    images
  end

  def networks() do
    {:ok, networks} = Bifroest.Openstack.Network.get_networks()
    networks
  end

  def keypairs(conn) do
    %Bifroest.Accounts.User{project_id: project_id} = current_user(conn)
    {:ok, keypairs} = Bifroest.Openstack.Compute.get_keypairs(project_id)
    keypairs
  end
end
