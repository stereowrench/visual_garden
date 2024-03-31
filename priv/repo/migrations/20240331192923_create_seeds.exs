defmodule VisualGarden.Repo.Migrations.CreateSeeds do
  use Ecto.Migration

  def change do
    create table(:seeds) do
      add :name, :text
      add :description, :text

      timestamps(type: :utc_datetime)
    end
  end
end
