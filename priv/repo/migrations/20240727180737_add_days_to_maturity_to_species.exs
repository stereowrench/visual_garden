defmodule VisualGarden.Repo.Migrations.AddDaysToMaturityToSpecies do
  use Ecto.Migration

  def change do
    alter table(:species) do
      add :days_to_maturity, :integer
    end

    execute """
      DROP INDEX unique_species;
    """

    execute """
      CREATE UNIQUE INDEX unique_species ON species (name, genus, coalesce(variant, ''), coalesce(cultivar, ''), coalesce(season, ''), coalesce(days_to_maturity, 0));
    """
  end
end
