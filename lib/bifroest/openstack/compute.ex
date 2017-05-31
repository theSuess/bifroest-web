defmodule Bifroest.Openstack.Compute do
  defmodule Flavor do
    defstruct [:id, :name, :ram, :vcpus]
  end

  defmodule Keypair do
    defstruct [:name, :fingerprint]
  end

  defmodule Server do
    defstruct [:id,
               :name,
               :imageRef,
               :flavorRef,
               :networks,
               :adminPass,
               :addresses,
               :key_name
              ]
    defmodule Address do
      defstruct [:addr,:version]
    end
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

  def get_keypairs(project_id,user_id) do
    case HTTPoison.get(@url <> "/#{project_id}/os-keypairs?user_id=#{user_id}",headers(project_id) ++ [{"OpenStack-API-Version","compute 2.35"}]) do
      {:ok, %HTTPoison.Response{body: body}} ->
        {:ok, %{"keypairs" => keypairs}} = body |> Poison.decode(as: %{"keypairs" => [%{"keypair" => %Keypair{}}]})
        kps = keypairs
          |> Enum.map(fn %{"keypair" => val} -> val end)
        {:ok, kps}
      _ -> {:error, "Unable to get flavors"}
    end
  end

  def create_server(%Server{} = server, project_id) do
    {:ok, body} = server
    |> Map.from_struct
    |> Enum.filter(fn {_, v} -> v != nil end)
    |> Enum.into(%{})
    |> (fn srv -> %{"server" => srv} end).()
    |> Poison.encode
    case HTTPoison.post(@url <> "/#{project_id}/servers",body,headers(project_id)) do
      {:ok, %HTTPoison.Response{body: body, status_code: 202}} ->
        {:ok, %{"server" => resp}} = body |> Poison.decode(as: %{"server" => %Server{}})
        {:ok, resp}
      {:ok, %HTTPoison.Response{body: body}} ->
        {:ok, resp} = body
        {:error, resp}
      _ -> {:error, "Unable to create server"}
    end
  end

  def get_server(id, project_id) do
    case HTTPoison.get(@url <> "/#{project_id}/servers/#{id}",headers(project_id)) do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
        {:ok, %{"server" => resp}} = body |> Poison.decode(as: %{"server" => %Server{}})
        {:ok, resp}
    end
  end

  def delete_server(%Server{id: id}, project_id) do
    case HTTPoison.delete(@url <> "/#{project_id}/servers/#{id}",headers(project_id)) do
      {:ok, %HTTPoison.Response{body: body, status_code: 204}} -> :ok
    end
  end
end
