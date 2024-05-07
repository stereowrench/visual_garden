defmodule VisualGarden.Repo.Migrations.ChangePlannerEntryDatesToRanges do
  use Ecto.Migration

  def change do
    alter table(:planner_entries) do
      remove :plant_date
      add :start_plant_date, :utc_datetime
      add :end_plant_date, :utc_datetime
      remove :mature_date
      add :days_to_maturity, :integer
      add :days_to_refuse, :integer
    end
  end
end
