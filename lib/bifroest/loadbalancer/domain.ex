defmodule Bifroest.Loadbalancer.Domain do
  use Ecto.Schema
  
  schema "loadbalancer_domains" do
    field :domain, :string
    field :server_id, :string
    belongs_to :user, Bifroest.Accounts.User

    timestamps()
  end
end
