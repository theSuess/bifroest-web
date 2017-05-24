defmodule Bifroest.Openstack.Network do
  defmodule Network do
    defstruct [:id, :name, :status]
  end

  import Bifroest.Openstack.Base

  @url Application.get_env(:bifroest,:openstack_network_url)

  def get_networks() do
    @url
    case HTTPoison.get(@url <> "/networks",headers()) do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
        {:ok, %{"networks" => images}} = body |> Poison.decode(as: %{"networks" => [%Network{}]})
        {:ok, images}
      {:ok, %HTTPoison.Response{body: body}} ->
        {:ok, resp} = body |> Poison.decode()
        {:error, resp}
      _ -> {:error, "Unable to get networks"}
    end
  end

  def update_security_gropus(id) do
  end
end
