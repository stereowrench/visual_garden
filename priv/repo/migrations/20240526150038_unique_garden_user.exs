defmodule VisualGarden.Repo.Migrations.UniqueGardenUser do
  use Ecto.Migration

  def change do
    create unique_index(:garden_users, [:user_id, :garden_id])
  end
end
