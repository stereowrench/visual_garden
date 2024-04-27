defmodule VisualGarden.Repo.Migrations.RenameVarToCultivar do
  use Ecto.Migration

  def change do
    rename table(:species), :var, to: :cultivar
  end
end
