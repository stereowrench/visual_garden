defmodule VisualGarden.Repo.Migrations.CreateSchedules do
  use Ecto.Migration

  def change do
    create table(:schedules) do
      add :start_month, :integer
      add :start_day, :integer
      add :end_month, :integer
      add :end_day, :integer
      add :end_month_adjusted, :integer
      add :region_id, references(:regions, on_delete: :delete_all)
      add :species_id, references(:species, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:schedules, [:region_id])
    create index(:schedules, [:species_id])
  end
end
