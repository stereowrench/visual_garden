defmodule VisualGarden.Repo.Migrations.FixSpeciesUnique do
  use Ecto.Migration

  def up do
    drop unique_index(:species, [:name, :genus, :variant, :cultivar])
    execute """
      CREATE UNIQUE INDEX unique_species ON species (name, genus, coalesce(variant, ''), coalesce(cultivar, ''))
    """
  end
end
