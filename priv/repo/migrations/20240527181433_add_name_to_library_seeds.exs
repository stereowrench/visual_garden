defmodule VisualGarden.Repo.Migrations.AddNameToLibrarySeeds do
  use Ecto.Migration

  def change do
    alter table(:library_seeds) do
      add :name, :string
    end
  end
end
