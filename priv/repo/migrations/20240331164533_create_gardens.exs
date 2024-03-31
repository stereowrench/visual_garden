defmodule VisualGarden.Repo.Migrations.CreateGardens do
  use Ecto.Migration

  def change do
    create table(:gardens) do
      add :name, :string
      timestamps(type: :utc_datetime)
    end
  end
end
