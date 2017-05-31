defmodule Bifroest.Openstack.Identity do
  require Logger
  import Bifroest.Openstack.Base

  @url Application.get_env(:bifroest,:openstack_auth_url)

  def create_user(email,project_id) do
    pwLength = Application.get_env(:bifroest,:password_length)
    password = :crypto.strong_rand_bytes(pwLength) |> Base.encode64 |> binary_part(0, pwLength)
    {:ok, body} = Poison.encode(
      %{
        user: %{
          enabled: true,
          name: email,
          password: password,
          default_project_id: project_id
        }
      }
    )
    case HTTPoison.post(@url <> "/users",body,headers()) do
      {:ok, %HTTPoison.Response{status_code: 201,body: body}} ->
        {:ok, %{"user" => %{"id" => user_id}}} = body |> Poison.decode
        Logger.info "Created User `#{email}` with password #{password}"
        resp = Bifroest.Web.Email.password_email(email,password) |> Bifroest.Mailer.deliver_later
        IO.inspect resp
        Logger.info "Sent email"
        {:ok, user_id}
      _ -> {:error, "Could not create User"}
    end
  end

  def create_project(email) do
    {:ok, body} = Poison.encode(
      %{
        project: %{
          name: email,
          description: "Project for user #{email}"
        }
      }
    )
    case HTTPoison.post(@url <> "/projects",body,headers()) do
      {:ok, %HTTPoison.Response{status_code: 201, body: body}} ->
        {:ok, %{"project" => %{"id" => project_id}}} = body |> Poison.decode
        assign_admin(project_id)
      {:ok, %HTTPoison.Response{} = resp} -> {:error, resp}
    end
  end

  def assign_user(user_id,project_id) do
    role_id = Application.get_env(:bifroest, :default_role_id)
    case HTTPoison.put(@url <> "/projects/#{project_id}/users/#{user_id}/roles/#{role_id}","",headers()) do
      {:ok, %HTTPoison.Response{status_code: 204}} ->
        {:ok,project_id}
      other ->
        IO.inspect other
        {:error, "Could not assign role to user"}
    end
  end

  def assign_admin(project_id) do
    role_id = Application.get_env(:bifroest, :admin_role_id)
    user_id = Application.get_env(:bifroest, :admin_user_id)
    case HTTPoison.put(@url <> "/projects/#{project_id}/users/#{user_id}/roles/#{role_id}","",headers()) do
      {:ok, %HTTPoison.Response{status_code: 204}} ->
        {:ok,project_id}
      other ->
        IO.inspect other
        {:error, "Could not assign role to user"}
    end
  end
end
