defmodule VisualGarden.Repo.Migrations.UniqueCommonNames do
  use Ecto.Migration

  def change do
    create unique_index(:species, [:common_name])
  end
end
