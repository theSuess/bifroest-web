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


  def start_link do
    GenServer.start_link(__MODULE__, nil, name: :lb_interface)
  end

  def get_host(domain) do
    GenServer.call(:lb_interface, {:get_host, domain})
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
  def get_domain!(id), do: Repo.get!(Domain, id)

  @doc """
  Creates a domain.

  ## Examples

      iex> create_domain(domain, %{field: value})
      {:ok, %Domain{}}

      iex> create_domain(domain, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_domain(attrs \\ %{}) do
    %Domain{}
    |> domain_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a domain.

  ## Examples

      iex> update_domain(domain, %{field: new_value})
      {:ok, %Domain{}}

      iex> update_domain(domain, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_domain(%Domain{} = domain, attrs) do
    domain
    |> domain_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Domain.

  ## Examples

      iex> delete_domain(domain)
      {:ok, %Domain{}}

      iex> delete_domain(domain)
  resources "/domains", DomainController, except: [:new, :edit]    {:error, %Ecto.Changeset{}}

  """
  def delete_domain(%Domain{} = domain) do
    Repo.delete(domain)
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
    |> cast(attrs, [:domain, :server_id, :user_id])
    |> validate_required([:domain, :server_id, :user_id])
    |> unique_constraint(:domain)
  end

  # Server Functions

  def init(_) do
    Exredis.start_link
  end

  def handle_call({:get_host, domain}, _from, client) do
    ret = client |> Exredis.query(["GET", "bfr:domains:#{domain}"])
    {:reply, ret, client}
  end
end
