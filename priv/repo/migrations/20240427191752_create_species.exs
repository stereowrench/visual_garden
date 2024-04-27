defmodule VisualGarden.Repo.Migrations.CreateSpecies do
  use Ecto.Migration

  def change do
    create table(:species) do
      add :name, :string
      add :genus_id, references(:genera, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:species, [:genus_id])
  end
end
