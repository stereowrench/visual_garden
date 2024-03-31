defmodule VisualGarden.Repo.Migrations.CreatePlants do
  use Ecto.Migration

  def change do
    create table(:plants) do
      add :seed_id, references(:seeds, on_delete: :nothing)
      add :product_id, references(:products, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:plants, [:seed_id])
    create index(:plants, [:product_id])
  end
end
