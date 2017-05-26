defmodule Bifroest.Openstack.Network do
  defmodule Network do
    defstruct [:id, :name, :status]
  end

  defmodule SecurityGroup do
    defstruct [:id, :name, :project_id]
  end

  import Bifroest.Openstack.Base

  @url Application.get_env(:bifroest,:openstack_network_url)

  def basic_tcp_rule(port,group_id) do
    %{"security_group_rule" => %{
         "direction" => "ingress",
         "port_range_min" => port,
         "port_range_max" => port,
         "protocol" => "tcp",
         "remote_ip_prefix" => "0.0.0.0/0",
         "security_group_id" => group_id
      }}
  end
  def http_rule(group_id), do: basic_tcp_rule(80,group_id)
  def https_rule(group_id), do: basic_tcp_rule(443,group_id)
  def ssh_rule(group_id), do: basic_tcp_rule(22,group_id)

  def get_networks() do
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

  def get_default_security_group(project_id) do
    case HTTPoison.get(@url <> "/security-groups",headers()) do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
        {:ok, %{"security_groups" => secgroups}} = body |> Poison.decode(as: %{"security_groups" => [%SecurityGroup{}]})
        grp = Enum.find(secgroups, fn(element) ->
          element.project_id == project_id && element.name == "default"
        end)
        if grp != nil do
          {:ok, grp}
        else
          get_default_security_group(project_id)
        end
      {:ok, %HTTPoison.Response{body: body}} ->
        {:ok, resp} = body |> Poison.decode()
        {:error, resp}
      _ -> {:error, "Unable to get security groups"}
    end
  end

  def add_security_group_rule(rule, group_id) do
    {:ok, body} = Poison.encode(rule.(group_id))
    case HTTPoison.post(@url <> "/security-group-rules",body, headers()) do
      {:ok, %HTTPoison.Response{body: body, status_code: 201}} ->
        Poison.decode(body)
      {:ok, %HTTPoison.Response{body: body}} ->
        {:ok, resp} = body |> Poison.decode()
        {:error, resp}
      _ -> {:error, "Unable modify security group"}
    end
  end

  def add_default_rules(project_id) do
    {:ok, %SecurityGroup{id: group_id}} = get_default_security_group(project_id)
    with {:ok, _} <- add_security_group_rule(&http_rule/1, group_id),
         {:ok, _} <- add_security_group_rule(&https_rule/1, group_id),
         {:ok, _} <- add_security_group_rule(&ssh_rule/1, group_id), do: :ok
  end
end
