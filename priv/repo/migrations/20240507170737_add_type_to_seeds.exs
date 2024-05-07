defmodule VisualGarden.Repo.Migrations.AddTypeToSeeds do
  use Ecto.Migration

  def change do
    alter table(:seeds) do
      add :type, :string
    end
  end
end
