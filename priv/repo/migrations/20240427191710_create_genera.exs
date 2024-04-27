defmodule VisualGarden.Repo.Migrations.CreateGenera do
  use Ecto.Migration

  def change do
    create table(:genera) do
      add :name, :string

      timestamps(type: :utc_datetime)
    end
  end
end
