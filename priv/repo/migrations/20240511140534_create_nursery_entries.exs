defmodule VisualGarden.Repo.Migrations.CreateNurseryEntries do
  use Ecto.Migration

  def change do
    create table(:nursery_entries) do
      add :sow_date, :date
      add :planner_entry_id, references(:planner_entries, on_delete: :nothing)
      add :seed_id, references(:seeds, on_delete: :nothing)
      add :garden_id, references(:garden, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:nursery_entries, [:planner_entry_id])
    create index(:nursery_entries, [:seed_id])
    create index(:nursery_entries, [:garden_id])
  end
end
