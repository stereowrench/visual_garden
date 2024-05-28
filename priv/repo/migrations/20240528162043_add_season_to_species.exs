defmodule VisualGarden.Repo.Migrations.AddSeasonToSpecies do
  use Ecto.Migration

  def change do
    alter table(:species) do
      add :season, :string
    end

    execute """
      DROP INDEX unique_species;
    """

    execute """
      CREATE UNIQUE INDEX unique_species ON species (name, genus, coalesce(variant, ''), coalesce(cultivar, ''), coalesce(season, ''));
    """
  end
end
