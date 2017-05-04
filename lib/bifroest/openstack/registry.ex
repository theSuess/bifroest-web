defmodule Bifroest.Openstack.Registry do
  use GenServer
  require Logger

  @api Application.get_env(:bifroest, :openstack_api)

  def get_token(project_id) do
    GenServer.call(:os_registry, {:get_token,project_id})
  end

  def get_admin_token() do
    admin_project_id = Application.get_env(:bifroest,:admin_project_id)
    get_token(admin_project_id)
  end

  def start_link do
    GenServer.start_link(__MODULE__, nil, name: :os_registry)
  end

  # Server Functions

  defp new_token(project_id,state) do
    {:ok, {token,exp} = t} = @api.new_token(project_id)
    n_state = Map.put(state, project_id, {token,exp})
    {:ok, t, n_state}
  end

  def init(_) do
    admin_project_id = Application.get_env(:bifroest,:admin_project_id)
    with {:ok,_,state} <- new_token(admin_project_id,%{}),
           do: {:ok, state}
  end

  def handle_call({:get_token,project_id}, _from, state) do
    case Map.get(state,project_id) do
      {token,exp} ->
        if DateTime.compare(exp, DateTime.utc_now) == :lt do
          Logger.info "Requesting new token..."
          {:ok, {ntoken,_}, new_state} = new_token(project_id,state)
          {:reply, ntoken, new_state}
        else
          {:reply, token, state}
        end
      _ ->
        {:ok, {ntoken,_} ,new_state} = new_token(project_id,state)
        {:reply, ntoken, new_state}
    end
  end

end
