defmodule Bifroest.Web.UserController do
  use Bifroest.Web, :controller

  require Logger
  alias Bifroest.Accounts
  alias Bifroest.Accounts.User

  action_fallback Bifroest.Web.FallbackController

  def update(conn, %{"id" => raw_id, "approved" => "false"}) do
    {id,_} = Integer.parse(raw_id)
    current_user = Guardian.Plug.current_resource(conn)
    user = Accounts.get_user!(id)
    if current_user.is_admin do
      with {:ok, %User{} = user} <- Accounts.reject_user(user) do
        render(conn, "show.json", user: user)
      end
    else
      send_resp(conn, :forbidden,"")
    end
  end

  def update(conn, %{"id" => raw_id, "approved" => approved}) do
    {id,_} = Integer.parse(raw_id)
    current_user = Guardian.Plug.current_resource(conn)
    user = Accounts.get_user!(id)
    if current_user.is_admin do
      with resp <- Accounts.approve_user(user) do
        send_resp(conn,:ok,"")
      end
    else
      send_resp(conn, :forbidden,"")
    end
  end

  def update(conn, %{"id" => raw_id, "admin" => admin}) do
    {id,_} = Integer.parse(raw_id)
    current_user = Guardian.Plug.current_resource(conn)
    user = Accounts.get_user!(id)
    if current_user.is_admin do
      params = %{"is_admin" => admin}
      with {:ok, %User{} = user} <- Accounts.update_user(user, params) do
        render(conn, "show.json", user: user)
      end
    else
      send_resp(conn, :forbidden,"")
    end
  end
end
