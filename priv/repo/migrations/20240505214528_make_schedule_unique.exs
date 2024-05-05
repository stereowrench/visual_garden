defmodule VisualGarden.Repo.Migrations.MakeScheduleUnique do
  use Ecto.Migration

  def change do
    create unique_index(:schedules, [:species_id, :region_id])
  end
end
