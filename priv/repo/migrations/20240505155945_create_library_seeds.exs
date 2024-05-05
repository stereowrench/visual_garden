defmodule VisualGarden.Repo.Migrations.CreateLibrarySeeds do
  use Ecto.Migration

  def change do
    create table(:library_seeds) do
      add :type, :string
      add :days_to_maturation, :integer
      add :manufacturer, :string
      add :species_id, references(:species, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:library_seeds, [:species_id])
  end
end
