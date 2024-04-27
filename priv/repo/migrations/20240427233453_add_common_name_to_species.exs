defmodule VisualGarden.Repo.Migrations.AddCommonNameToSpecies do
  use Ecto.Migration

  def change do
    alter table(:species) do
      add :common_name, :string
    end
  end
end
