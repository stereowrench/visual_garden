defmodule VisualGarden.Repo.Migrations.CreatePlanners do
  use Ecto.Migration

  def change do
    create table(:planners) do
      add :garden_id, references(:gardens, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:planners, [:garden_id])
  end
end
