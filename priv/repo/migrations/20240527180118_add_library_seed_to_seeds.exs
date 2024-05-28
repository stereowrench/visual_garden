defmodule VisualGarden.Repo.Migrations.AddLibrarySeedToSeeds do
  use Ecto.Migration

  def change do
    alter table(:seeds) do
      add :library_seed_id, references(:library_seeds)
    end

    create unique_index(:seeds, [:garden_id, :library_seed_id])
  end
end
