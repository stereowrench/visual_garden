defmodule VisualGarden.Repo.Migrations.AddLibraryUniqueness do
  use Ecto.Migration

  def change do
    create unique_index(:regions, [:name])
    create unique_index(:species, [:name, :genus_id])
    create unique_index(:genera, [:name])
  end
end
