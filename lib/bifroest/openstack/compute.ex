defmodule Bifroest.Openstack.Compute do
  use HTTPoison.Base

  def process_url(url) do
    Application.get_env(:bifroest,:openstack_compute_url) <> url
  end

  def process_request_headers(headers) do
    token = Bifroest.Openstack.Registry.get_token
    Keyword.put(headers, :"X-Auth-Token", token)
  end

  # def process_response_body(body) do
  #   body
  #   |> Poison.decode!
  #   |> Enum.map(fn({k, v}) -> {String.to_atom(k), v} end)
  # end
end
