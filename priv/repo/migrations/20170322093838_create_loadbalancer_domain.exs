defmodule Bifroest.Repo.Migrations.CreateBifroest.Loadbalancer.Domain do
  use Ecto.Migration

  def change do
    create table(:loadbalancer_domains) do
      add :domain, :string
      add :server_id, :string
      add :server_addr, :string
      add :user_id, references(:accounts_users, on_delete: :delete_all)

      timestamps()
    end

    create unique_index(:loadbalancer_domains, [:domain])
  end
end
