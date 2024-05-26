defmodule VisualGarden.Repo.Migrations.AddAuthFieldsToGarden do
  use Ecto.Migration

  def change do
    alter table(:gardens) do
      add :owner_id, references(:users)
      add :visibility, :string
    end
  end
end
