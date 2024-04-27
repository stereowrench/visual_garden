defmodule VisualGarden.Repo.Migrations.AddVarToSpecies do
  use Ecto.Migration

  def change do
    alter table(:species) do
      add :var, :string
    end

    drop unique_index(:species, [:name, :genus_id])
    create unique_index(:species, [:name, :genus_id, :var])
  end
end
