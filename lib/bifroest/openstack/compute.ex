defmodule Bifroest.Openstack.Compute do
  defmodule Flavor do
    defstruct [:id, :name, :ram, :vcpus]
  end

  defmodule Keypair do
    defstruct [:name, :fingerprint]
  end

  defmodule Server do
    defstruct [:id, :name, :imageRef, :flavorRef, :networks]
  end

  import Bifroest.Openstack.Base

  @url Application.get_env(:bifroest,:openstack_compute_url)

  def get_flavors() do
    admin_project_id = Application.get_env(:bifroest,:admin_project_id)
    get_flavors(admin_project_id)
  end

  def get_flavors(project_id) do
    case HTTPoison.get(@url <> "/#{project_id}/flavors/detail",headers()) do
      {:ok, %HTTPoison.Response{body: body}} ->
        {:ok, %{"flavors" => flavors}} = body |> Poison.decode(as: %{"flavors" => [%Flavor{}]})
        {:ok, flavors}
      _ -> {:error, "Unable to get keypairs"}
    end
  end

  def get_keypairs(project_id) do
    case HTTPoison.get(@url <> "/#{project_id}/os-keypairs",headers(project_id)) do
      {:ok, %HTTPoison.Response{body: body}} ->
        {:ok, %{"keypairs" => keypairs}} = body |> Poison.decode(as: %{"keypairs" => [%{"keypair" => %Keypair{}}]})
        kps = keypairs |> Enum.map(fn %{"keypair" => val} -> val end)
        {:ok, kps}
      _ -> {:error, "Unable to get flavors"}
    end
  end

  def create_server(%Server{} = server, project_id) do
    {:ok,srv} = Poison.encode(%{"server" => server})
    body = strip_json_null(srv)
    case HTTPoison.post(@url <> "/#{project_id}/servers",body,headers(project_id)) do
      {:ok, %HTTPoison.Response{body: body, status_code: 202}} ->
        {:ok, resp} = body |> Poison.decode
        resp
      {:ok, %HTTPoison.Response{body: body}} ->
        {:ok, resp} = body |> Poison.decode
        {:error, resp}
      _ -> {:error, "Unable to create server"}
    end
  end

  defp strip_json_null(string) do
    Regex.replace(~r/\"([^\"]+)\":null(,?)/, string, "")
  end
end
