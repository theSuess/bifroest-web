defmodule Bifroest.Accounts.User do
  use Ecto.Schema

  schema "accounts_users" do
    field :email, :string
    field :name, :string
    field :is_admin, :boolean
    field :is_permitted, :boolean

    timestamps()
  end
end
