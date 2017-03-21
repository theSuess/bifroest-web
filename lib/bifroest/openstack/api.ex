defmodule Bifroest.Openstack.Api do
  require Logger
  def new_token do
    user = Application.get_env(:bifroest,:openstack_username)
    password = Application.get_env(:bifroest,:openstack_password)
    url = Application.get_env(:bifroest,:openstack_auth_url)
    {:ok, body} = Poison.encode(
      %{
        auth: %{
          identity: %{
            methods: ["password"],
            password: %{
              user: %{
                name: user,
                password: password,
                domain: %{
                  name: "default"
                }
              }
            }
          }
        }
      }
    )
    case HTTPoison.post(url <> "/auth/tokens",body,[{"Content-Type","application/json"}]) do
      {:ok, %HTTPoison.Response{headers: [_,_,{"X-Subject-Token",token} | _],body: body}} ->
        {:ok, %{"token" => %{"expires_at" => exp}}} = body |> Poison.decode
        Logger.info("Aquired new token expiring at: #{exp}")
        {:ok, time,_} = DateTime.from_iso8601(exp)
        {:ok, {token,time}}
      _ -> {:error, "Could not get token"}
    end
  end
end
