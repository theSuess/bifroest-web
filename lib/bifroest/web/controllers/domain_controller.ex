defmodule Bifroest.Web.DomainController do
  use Bifroest.Web, :controller

  require Logger
  alias Bifroest.Loadbalancer
  alias Bifroest.Loadbalancer.Domain

  action_fallback Bifroest.Web.FallbackController

  def index(conn, _params) do
    domains = Loadbalancer.list_domains()
    render(conn, "index.json", domains: domains)
  end

  def create(conn, %{"domain" => request_params}) do
    user = Guardian.Plug.current_resource(conn)
    with domain_params <- Map.put(request_params,"user_id",user.id),
         {:ok, %Domain{} = domain} <- Loadbalancer.create_domain(domain_params)
      do
      conn
      |> put_status(:created)
      |> put_resp_header("location", domain_path(conn, :show, domain))
      |> render("show.json", domain: domain)
    end
  end

  def show(conn, %{"id" => id}) do
    domain = Loadbalancer.get_domain!(id)
    render(conn, "show.json", domain: domain)
  end

  def update(conn, %{"id" => id, "domain" => domain_params}) do
    domain = Loadbalancer.get_domain!(id)
    {:ok, domain}
    current_user = Guardian.Plug.current_resource(conn)
    if current_user.is_admin || domain.user_id == current_user.id do
      with {:ok, %Domain{} = domain} <- Loadbalancer.update_domain(domain, domain_params) do
        render(conn, "show.json", domain: domain)
      end
    else
      send_resp(conn, :forbidden,"")
    end

  end

  def delete(conn, %{"id" => id}) do
    domain = Loadbalancer.get_domain!(id)
    user = Guardian.Plug.current_resource(conn)
    with {:ok, %Domain{}} <- Loadbalancer.delete_domain(domain,user) do
      send_resp(conn, :no_content, "")
    end
  end
end
