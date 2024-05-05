defmodule VisualGarden.Repo.Migrations.CreatePlannerEntries do
  use Ecto.Migration

  def change do
    create table(:planner_entries) do
      add :plant_date, :utc_datetime
      add :mature_date, :utc_datetime
      add :common_name, :string
      add :bed_id, references(:products, on_delete: :nothing)
      add :seed_id, references(:seeds, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:planner_entries, [:bed_id])
    create index(:planner_entries, [:seed_id])
  end
end
