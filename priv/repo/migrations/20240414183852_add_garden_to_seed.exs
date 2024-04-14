defmodule VisualGarden.Repo.Migrations.AddGardenToSeed do
  use Ecto.Migration

  def change do
    alter table(:seeds) do
      add :garden_id, references(:gardens)
    end
  end
end
