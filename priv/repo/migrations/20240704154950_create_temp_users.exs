defmodule VisualGarden.Repo.Migrations.CreateTempUsers do
  use Ecto.Migration

  def change do
    create table(:temp_users) do

      timestamps(type: :utc_datetime)
    end
  end
end
