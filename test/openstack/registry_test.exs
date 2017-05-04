defmodule Bifroest.Openstack.RegistryTest do
  use ExUnit.Case

  test "Retrieving token" do
    token = Bifroest.Openstack.Registry.get_token("some_project")
    assert token == "TEST_TOKEN"
  end

end
