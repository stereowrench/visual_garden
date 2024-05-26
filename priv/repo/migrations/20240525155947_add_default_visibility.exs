defmodule VisualGarden.Repo.Migrations.AddDefaultVisibility do
  use Ecto.Migration

  def up do
    execute("update gardens set visibility = 'public' where visibility IS NULL")
  end
end
