defmodule VisualGarden.Repo.Migrations.AddDaysToMaturationToSeeds do
  use Ecto.Migration

  def change do
    alter table(:seeds) do
      add :days_to_maturation, :integer
    end
  end
end
