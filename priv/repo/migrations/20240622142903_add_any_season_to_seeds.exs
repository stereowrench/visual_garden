defmodule VisualGarden.Repo.Migrations.AddAnySeasonToSeeds do
  use Ecto.Migration

  def change do
    alter table(:seeds) do
      add :any_season, :boolean
      add :harvest_species_id, references(:species, on_delete: :nilify_all)
    end
  end
end
