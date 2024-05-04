defmodule VisualGarden.Repo.Migrations.AddRowAndColumnToPlants do
  use Ecto.Migration

  def change do
    alter table(:plants) do
      add :row, :integer
      add :column, :integer
    end
  end
end
