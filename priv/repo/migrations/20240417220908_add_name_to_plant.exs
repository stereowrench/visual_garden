defmodule VisualGarden.Repo.Migrations.AddNameToPlant do
  use Ecto.Migration

  def change do
    alter table(:plants) do
      add :name, :string
    end
  end
end
