defmodule VisualGarden.Repo.Migrations.AddLengthAndWidthToBeds do
  use Ecto.Migration

  def change do
    alter table(:products) do
      add :length, :integer
      add :width, :integer
    end
  end
end
