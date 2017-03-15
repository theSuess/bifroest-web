defmodule Bifroest.GuardianSerializer do
  @behaviour Guardian.Serializer

  alias Bifroest.Accounts
  alias Bifroest.Accounts.User

  def for_token(user = %User{}) do
    { :ok, "User:#{user.id}" }
  end
  def for_token(_), do: { :error, "Unknown resource type" }

  def from_token("User:" <> id) do
    {uid,_} = Integer.parse(id)
    case Accounts.get_user(uid) do
      nil -> {:error, "No such user"}
      user -> {:ok, user}
    end
  end

  def from_token(_) do
    { :error, "Unknown resource type" }
  end

end
