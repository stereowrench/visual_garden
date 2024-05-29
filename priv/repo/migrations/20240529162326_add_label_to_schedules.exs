defmodule VisualGarden.Repo.Migrations.AddLabelToSchedules do
  use Ecto.Migration

  def change do
    alter table(:schedules) do
      add :label, :string
    end
  end
end
