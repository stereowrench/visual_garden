defmodule VisualGarden.Repo.Migrations.ConvertScheduleMoToDecimal do
  use Ecto.Migration

  def change do
    alter table(:schedules) do
      modify :start_month, :decimal, precision: 3, scale: 1
      modify :end_month, :decimal, precision: 3, scale: 1
      modify :end_month_adjusted, :decimal, precision: 3, scale: 1
    end
  end
end
