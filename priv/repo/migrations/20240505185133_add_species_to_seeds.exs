defmodule VisualGarden.Repo.Migrations.AddSpeciesToSeeds do
  use Ecto.Migration

  def change do
    alter table(:seeds) do
      add :species_id, references(:species, on_delete: :nothing)
    end
  end
end
