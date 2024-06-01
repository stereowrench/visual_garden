defmodule VisualGarden.Repo.Migrations.AddUuidToLibrarySeed do
  use Ecto.Migration

  def change do
    alter table(:library_seeds) do
      add :uuid, :uuid
    end
  end
end
