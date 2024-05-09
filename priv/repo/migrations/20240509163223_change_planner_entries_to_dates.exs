defmodule VisualGarden.Repo.Migrations.ChangePlannerEntriesToDates do
  use Ecto.Migration

  def change do
    alter table(:planner_entries) do
      modify :start_plant_date, :date
      modify :end_plant_date, :date
    end
  end
end
