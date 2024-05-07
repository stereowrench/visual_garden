defmodule VisualGarden.Repo.Migrations.AddNurseryLeadToSchedules do
  use Ecto.Migration

  def change do
    alter table(:schedules) do
      add :nursery_lead_weeks_min, :integer
      add :nursery_lead_weeks_max, :integer
    end
  end
end
