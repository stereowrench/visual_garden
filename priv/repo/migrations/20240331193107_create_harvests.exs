defmodule VisualGarden.Repo.Migrations.CreateHarvests do
  use Ecto.Migration

  def change do
    create table(:harvests) do
      add :quantity, :decimal
      add :units, :string
      add :plant_id, references(:plants, on_delete: :nothing)
      add :product_id, references(:products, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:harvests, [:plant_id])
    create index(:harvests, [:product_id])
  end
end
