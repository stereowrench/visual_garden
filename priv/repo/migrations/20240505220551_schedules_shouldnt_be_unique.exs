defmodule VisualGarden.Repo.Migrations.SchedulesShouldntBeUnique do
  use Ecto.Migration

  def change do
    drop unique_index(:schedules, [:species_id, :region_id])
  end
end
