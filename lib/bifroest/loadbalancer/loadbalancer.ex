defmodule Bifroest.Loadbalancer do
  use GenServer
  @moduledoc """
  The boundary for the Loadbalancer system.
  """

  import Ecto.{Query, Changeset}, warn: false
  alias Bifroest.Repo

  alias Bifroest.Loadbalancer.Domain
  alias Bifroest.Accounts.User
  require Ecto.Query
  require Logger


  def start_link do
    GenServer.start_link(__MODULE__, nil, name: :lb_interface)
  end

  def get_host(domain) do
    GenServer.call(:lb_interface, {:get_host, domain})
  end

  def set_host(domain, host) do
    GenServer.cast(:lb_interface, {:set_host, domain, host})
  end

  def del_domain(domain) do
    GenServer.cast(:lb_interface, {:del_domain, domain})
  end

  @doc """
  Lists all Domains with their respective users

  ## Examples

  iex> list_domains()
  [%Domain{}, ...]

  """
  def list_domains() do
    Repo.all(Domain)
  end

  @doc """
  Returns the list of domains by a specific user

  ## Examples

      iex> list_domains(%User{id: 4})
      [%Domain{}, ...]

  """
  def list_domains(%User{id: id}) do
    Ecto.Query.from(d in Domain, where: d.user_id == ^id) |> Repo.all()
  end

  @doc """
  Gets a single domain.

  Raises `Ecto.NoResultsError` if the Domain does not exist.

  ## Examples

      iex> get_domain!(123)
      %Domain{}

      iex> get_domain!(456)
      ** (Ecto.NoResultsError)

  """
  def get_domain!(id), do: Repo.get!(Domain, id) |> Repo.preload(:user)

  @doc """
  Creates a domain.

  ## Examples

      iex> create_domain(domain, %{field: value})
      {:ok, %Domain{}}

      iex> create_domain(domain, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_domain(attrs \\ %{}) do
    res = %Domain{}
    |> domain_changeset(attrs)
    |> Repo.insert()
    case res do
      {:error, _} = err -> err
      {:ok, %Domain{domain: d, server_addr: h}} ->
        set_host(d,h)
        res
    end
  end

  @doc """
  Updates a domain.

  ## Examples

      iex> update_domain(domain, %{field: new_value})
      {:ok, %Domain{}}

      iex> update_domain(domain, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_domain(%Domain{} = domain, %{"domain" => d, "server_addr" => h} = attrs) do
    set_host(d,h)
    domain
    |> domain_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Domain, checking if the user is permitted to do so

  ## Examples

      iex> delete_domain(domain,user)
      {:ok, %Domain{}}
  """
  def delete_domain(%Domain{user: %User{project_id: project_id}} = domain, %User{is_admin: admin} = user) do
    if domain.user_id == user.id || admin do
      del_domain(domain.domain)
      if domain.server_id != nil do
        :ok = Bifroest.Openstack.Compute.delete_server(%Bifroest.Openstack.Compute.Server{id: domain.server_id},project_id)
      end
      Repo.delete(domain)
    else
      changeset = change(%Domain{})
      |> Ecto.Changeset.add_error(:unauthorized, "You are not authorized to delete this domain")
      {:error, changeset}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking domain changes.

  ## Examples

      iex> change_domain(domain)
      %Ecto.Changeset{source: %Domain{}}

  """
  def change_domain(%Domain{} = domain) do
    domain_changeset(domain, %{})
  end

  defp domain_changeset(%Domain{} = domain, attrs) do
    domain
    |> cast(attrs, [:domain, :server_addr, :server_id, :user_id])
    |> validate_required([:domain, :server_addr, :user_id])
    |> validate_url(:server_addr)
    |> unique_constraint(:domain)
  end

  def validate_url(changeset, field, options \\ []) do
    validate_change(changeset, field, fn _, url ->
      case is_url?(url) do
        true -> []
        false -> [{field, options[:message] || "Invalid URL"}]
      end
    end)
  end

  # Utility functions

  defp validate_uri(str) do
    uri = URI.parse(str)
    case uri do
      %URI{scheme: nil} -> {:error, uri}
      %URI{host: nil} -> {:error, uri}
      uri -> {:ok, uri}
    end
  end

  def is_url?(url) do
    val = with {:ok, uri} <- validate_uri(url),
               {:ok, _} <- :inet.gethostbyname(to_charlist uri.host),
      do: :valid
    case val do
      :valid -> true
      _ -> false
    end
  end

  # Server Functions

  def init(_) do
    Exredis.start_link
  end

  def handle_call({:get_host, domain}, _from, client) do
    ret = client |> Exredis.query(["GET", "bfr:domains:#{domain}"])
    {:reply, ret, client}
  end

  def handle_cast({:set_host, domain, host}, client) do
    client |> Exredis.query(["SET","bfr:domains:#{domain}",host])
    {:noreply, client}
  end

  def handle_cast({:del_domain, domain}, client) do
    client |> Exredis.query(["DEL","bfr:domains:#{domain}"])
    {:noreply, client}
  end
end
