defmodule VisualGarden.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :name, :string
      add :type, :string
      add :garden_id, references(:gardens, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:products, [:garden_id])
  end
end
