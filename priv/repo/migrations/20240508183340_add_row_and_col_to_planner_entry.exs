defmodule VisualGarden.Repo.Migrations.AddRowAndColToPlannerEntry do
  use Ecto.Migration

  def change do
    alter table(:planner_entries) do
      add :row, :integer
      add :column, :integer
    end
  end
end
