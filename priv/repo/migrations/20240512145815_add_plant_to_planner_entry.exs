defmodule VisualGarden.Repo.Migrations.AddPlantToPlannerEntry do
  use Ecto.Migration

  def change do
    alter table(:planner_entries) do
      add :plant_id, references(:plants, on_delete: :nilify_all)
    end
  end
end
