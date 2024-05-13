defmodule VisualGarden.Repo.Migrations.AddNurseryDatesToPlannerEntries do
  use Ecto.Migration

  def change do
    alter table(:planner_entries) do
      add :nursery_start, :date
      add :nursery_end, :date
    end
  end
end
