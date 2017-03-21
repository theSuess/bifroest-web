defmodule Bifroest.Openstack.ApiMock do
  def new_token do
    {:ok, {"TEST_TOKEN", DateTime.utc_now}}
  end
end
