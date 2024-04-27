defmodule VisualGarden.Repo.Migrations.CreateRegions do
  use Ecto.Migration

  def change do
    create table(:regions) do
      add :name, :string

      timestamps(type: :utc_datetime)
    end
  end
end
