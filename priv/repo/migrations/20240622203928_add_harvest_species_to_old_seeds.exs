defmodule VisualGarden.Repo.Migrations.AddHarvestSpeciesToOldSeeds do
  use Ecto.Migration

  def up do
    execute """
    UPDATE seeds SET harvest_species_id = species_id WHERE harvest_species_id IS NULL ;
    """
  end
end
