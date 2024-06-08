defmodule VisualGarden.Repo.Migrations.AddArchiveToPlants do
  use Ecto.Migration

  def change do
    alter table(:plants) do
      add :archived, :boolean
    end
  end
end
