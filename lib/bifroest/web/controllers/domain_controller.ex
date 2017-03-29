defmodule Bifroest.Web.DomainController do
  use Bifroest.Web, :controller

  alias Bifroest.Loadbalancer
  alias Bifroest.Loadbalancer.Domain

  action_fallback Bifroest.Web.FallbackController

  def index(conn, _params) do
    domains = Loadbalancer.list_domains()
    render(conn, "index.json", domains: domains)
  end

  def create(conn, %{"domain" => domain_params}) do
    with {:ok, %Domain{} = domain} <- Loadbalancer.create_domain(domain_params) do
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

    with {:ok, %Domain{} = domain} <- Loadbalancer.update_domain(domain, domain_params) do
      render(conn, "show.json", domain: domain)
    end
  end

  def delete(conn, %{"id" => id}) do
    domain = Loadbalancer.get_domain!(id)
    with {:ok, %Domain{}} <- Loadbalancer.delete_domain(domain) do
      send_resp(conn, :no_content, "")
    end
  end
end
