defmodule VisualGarden.Repo.Migrations.RenameEventAssocs do
  use Ecto.Migration

  def change do
    rename table(:event_logs), :transferred_from, to: :transferred_from_id
    rename table(:event_logs), :transferred_to, to: :transferred_to_id
  end
end
