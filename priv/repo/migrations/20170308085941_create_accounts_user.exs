defmodule Bifroest.Repo.Migrations.CreateBifroest.Accounts.User do
  use Ecto.Migration

  def change do
    create table(:accounts_users) do
      add :email, :string
      add :name, :string

      timestamps()
    end

    create unique_index(:accounts_users, [:email])
  end
end
