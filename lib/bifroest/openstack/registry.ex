defmodule Bifroest.Openstack.Registry do
  use GenServer
  require Logger

  @api Application.get_env(:bifroest, :openstack_api)

  def get_token do
    GenServer.call(:os_registry, :get_token)
  end

  def start_link do
    GenServer.start_link(__MODULE__, nil, name: :os_registry)
  end

  # Server Functions

  defp new_token do
    @api.new_token
  end

  def init(_) do
    with {:ok,{token,exp}} <- new_token(),
    #       {:ok,catalog} <- get_service_catalog(token),
           do: {:ok, %{token: {token,exp}}}
  end

  def handle_call(:get_token, _from, %{token: {token,exp}} = state) do
    if DateTime.compare(exp, DateTime.utc_now) == :lt do
      Logger.info "Requesting new token..."
      {:ok, {ntoken,_} = new_state} = new_token()
      {:reply, ntoken, new_state}
    else
      {:reply, token, state}
    end
  end
end
