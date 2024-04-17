defmodule VisualGarden.Repo.Migrations.AddQtyToPlant do
  use Ecto.Migration

  def change do
    alter table(:plants) do
      add :qty, :integer
    end
  end
end
