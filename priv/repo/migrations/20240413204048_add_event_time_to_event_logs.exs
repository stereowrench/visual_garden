defmodule VisualGarden.Repo.Migrations.AddEventTimeToEventLogs do
  use Ecto.Migration

  def change do
    alter table(:event_logs) do
      add :event_time, :utc_datetime
      remove :watered
      remove :tilled
    end

  end
end
