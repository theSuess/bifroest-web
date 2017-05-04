defmodule Bifroest.Openstack.Base do

  def token() do
    Bifroest.Openstack.Registry.get_admin_token()
  end

  def token(project_id) do
    Bifroest.Openstack.Registry.get_token(project_id)
  end

  def headers do
    [{"X-Auth-Token",token()},{"Content-Type","application/json"}]
  end

  def headers(project_id) do
    [{"X-Auth-Token",token(project_id)},{"Content-Type","application/json"}]
  end
end
