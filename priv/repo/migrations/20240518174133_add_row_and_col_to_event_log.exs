defmodule VisualGarden.Repo.Migrations.AddRowAndColToEventLog do
  use Ecto.Migration

  def change do
    alter table(:event_logs) do
      add :row, :integer
      add :column, :integer
    end
  end
end
