defmodule VisualGarden.Repo.Migrations.AddPlantableTypeToSchedules do
  use Ecto.Migration

  def change do
    alter table(:schedules) do
      add :plantable_types, {:array, :string}
    end
  end
end
