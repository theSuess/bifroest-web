defmodule Bifroest.Openstack.ApiMock do
  def new_token(_) do
    {:ok, {"TEST_TOKEN", DateTime.utc_now}}
  end
end
