defmodule VisualGarden.Repo.Migrations.AddTzAndRegionToWizardGardens do
  use Ecto.Migration

  def change do
    alter table(:wizard_gardens) do
      add :tz, :string
      add :region_id, references(:regions, on_delete: :delete_all)
    end
  end
end
