defmodule Bifroest.Web.DomainController do
  use Bifroest.Web, :controller

  require Logger
  alias Bifroest.Loadbalancer
  alias Bifroest.Loadbalancer.Domain
  alias Bifroest.Openstack.Compute
  alias Bifroest.Openstack.Compute.Server

  action_fallback Bifroest.Web.FallbackController

  @internal_network_name Application.get_env(:bifroest, :internal_network_name)

  def index(conn, _params) do
    domains = Loadbalancer.list_domains()
    render(conn, "index.json", domains: domains)
  end

  def create(conn, %{"server" => %{"name" => name, "public" => public} = server_params, "domain" => domain_req_params}) do
    server = to_struct(Server, server_params)
    user = Guardian.Plug.current_resource(conn)
    result = with domain_params <- Map.put(domain_req_params,"user_id", user.id),
         {:ok, %Server{id: server_id, adminPass: pwd}} <- Compute.create_server(server, user.project_id),
         %Bamboo.Email{} = Bifroest.Web.Email.server_email(user.email, name, pwd, server_id) |> Bifroest.Mailer.deliver_later,
         :ok <- Process.sleep(5000),
         _ <- Bifroest.Openstack.Network.add_default_rules(user.project_id),
         {:ok, %Server{addresses: %{@internal_network_name => [%{"addr" => addr}]}}} <- Compute.get_server(server_id,user.project_id),
         server_addr <- build_url(addr),
         final_params <- Map.put(domain_params,"server_addr", server_addr) |> Map.put("server_id",server_id),
         {:ok, %Domain{} = domain} <- Loadbalancer.create_domain(final_params)
    do
      {:ok, domain}
    end
    case result do
      {:ok, domain} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", domain_path(conn, :show, domain))
        |> render("show.json", domain: domain)
      otherwise ->
        IO.inspect otherwise
        conn |> redirect(to: "/")
    end
  end

  defp build_url(url) do
    "http://#{url}:80/"
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
    case  Loadbalancer.delete_domain(domain,user) do
      {:ok, %Domain{}} -> send_resp(conn, :no_content, "")
      {:error, _reason} ->
        send_resp(conn,:forbidden,"")
    end
  end

  defp to_struct(kind, %{"public" => public} = attrs) do
    struct = struct(kind)
    int_net = Application.get_env(:bifroest, :internal_network_id)
    srv = if public do
      pub_net = Application.get_env(:bifroest, :public_network_id)
      Map.put(attrs, "networks", [%{uuid: pub_net},%{uuid: int_net}])
    else
      Map.put(attrs, "networks", [%{uuid: int_net}])
    end
    Enum.reduce Map.to_list(struct), struct, fn {k, _}, acc ->
      case Map.fetch(srv, Atom.to_string(k)) do
        {:ok, v} -> %{acc | k => v}
        :error -> acc
      end
    end
  end
end
