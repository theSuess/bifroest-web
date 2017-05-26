defmodule Bifroest.Accounts do
  @moduledoc """
  The boundary for the Accounts system.
  """

  import Ecto.{Query, Changeset}, warn: false
  alias Bifroest.Repo
  require Logger

  alias Bifroest.Accounts.User

  alias Ueberauth.Auth
  @doc """
  Returns the list of users.

  ## Examples

  iex> list_users()
  [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user.

  ## Examples

  iex> get_user!(123)
  {:ok, %User{}}

  """
  def get_user(id) when is_integer(id), do: Repo.get(User, id)
  def get_user(email) when is_bitstring(email), do: Repo.get_by(User,email: email)

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

  iex> get_user!(123)
  %User{}

  iex> get_user!(456)
  ** (Ecto.NoResultsError)

  """
  def get_user!(id) when is_integer(id), do: Repo.get!(User, id)

  @doc """
  Creates a user.

  ## Examples

  iex> create_user(user, %{field: value})
  {:ok, %User{}}

  iex> create_user(user, %{field: bad_value})
  {:error, %Ecto.Changeset{}}

  """
  def create_user(%{email: email} =attrs) do
    %User{}
    |> user_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Approves a user and create the openstack login
  """

  def approve_user(%User{email: email} = user) do
    with {:ok, project_id} <- Bifroest.Openstack.Identity.create_project(email),
         :ok <- Bifroest.Openstack.Network.add_default_rules(project_id),
         {:ok, user_id} <- Bifroest.Openstack.Identity.create_user(email,project_id),
         {:ok, project_id} <- Bifroest.Openstack.Identity.assign_user(user_id,project_id)
      do
      user
        |> user_changeset(%{project_id: project_id, user_id: user_id})
        |> Repo.update()
      end
  end

  def reject_user(%User{} = user) do
    user
    |> user_changeset(%{project_id: nil})
    |> Repo.update()
  end

  @doc """
  Updates a user.

  ## Examples

  iex> update_user(user, %{field: new_value})
  {:ok, %User{}}

  iex> update_user(user, %{field: bad_value})
  {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> user_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a User.

  ## Examples

  iex> delete_user(user)
  {:ok, %User{}}

  iex> delete_user(user)
  {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

  iex> change_user(user)
  %Ecto.Changeset{source: %User{}}

  """
  def change_user(%User{} = user) do
    user_changeset(user, %{})
  end

  defp user_changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:email,:name,:is_admin,:project_id, :user_id])
    |> validate_required([:email,:name])
    |> unique_constraint(:email)
  end

  def find_or_create(%Auth{} = auth) do
    email =  auth.info.email
    [_ ,domain] = email |> String.split("@")
    cond do
      domain != Application.get_env(:bifroest,:organization_name) ->
        {:error, "Invalid Organization Domain"}
      true ->
        case get_user(email) do
          nil -> create_user(basic_info(auth))
          user -> {:ok, user}
        end
    end
  end

  defp name_from_auth(auth) do
    if auth.info.name do
      auth.info.name
    else
      name = [auth.info.first_name, auth.info.last_name]
      |> Enum.filter(&(&1 != nil and &1 != ""))

      cond do
        length(name) == 0 -> auth.info.nickname
        true -> Enum.join(name, " ")
      end
    end
  end

  defp basic_info(auth) do
    %{name: name_from_auth(auth), email: auth.info.email}
  end

end
