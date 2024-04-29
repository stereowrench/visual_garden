defmodule VisualGarden.Repo.Migrations.RemoveGenera do
  use Ecto.Migration

  def change do
    drop table(:taxonomy_search)
    drop unique_index(:species, [:name, :genus_id, :var])
    alter table(:species) do
      remove :genus_id
      add :genus, :string
      add :variant, :string
    end
    drop table(:genera)
    create unique_index(:species, [:name, :genus, :variant, :cultivar])
  end
end
