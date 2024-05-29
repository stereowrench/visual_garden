defmodule VisualGarden.Repo.Migrations.AddUuidToSpecies do
  use Ecto.Migration

  def change do
    alter table(:species) do
      add :uuid, :uuid
    end
  end
end
