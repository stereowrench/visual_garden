defmodule VisualGarden.Repo.Migrations.ConvertScheduleBackToInteger do
  use Ecto.Migration

  def change do
    alter table(:schedules) do
      modify :start_month, :integer
      modify :end_month, :integer
      modify :end_month_adjusted, :integer
    end
  end
end
