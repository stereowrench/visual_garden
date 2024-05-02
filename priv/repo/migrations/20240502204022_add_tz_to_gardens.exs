defmodule VisualGarden.Repo.Migrations.AddTzToGardens do
  use Ecto.Migration

  def change do
    alter table(:gardens) do
      add :tz, :string
    end
  end
end
