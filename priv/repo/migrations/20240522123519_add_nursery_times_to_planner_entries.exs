defmodule VisualGarden.Repo.Migrations.AddNurseryTimesToPlannerEntries do
  use Ecto.Migration

  def change do
    alter table(:planner_entries) do
      add :min_lead, :integer
      add :max_lead, :integer
    end
  end
end
