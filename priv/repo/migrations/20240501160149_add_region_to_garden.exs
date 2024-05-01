defmodule VisualGarden.Repo.Migrations.AddRegionToGarden do
  use Ecto.Migration

  def change do
    alter table(:gardens) do
      add :region_id, references(:regions)
    end
  end
end
