defmodule VisualGarden.Repo.Migrations.AddOriginalLinksToWizardRecords do
  use Ecto.Migration

  def change do
    alter table(:wizard_gardens) do
      add :garden_id, references(:gardens, on_delete: :delete_all)
    end

    alter table(:wizard_beds) do
      add :bed_id, references(:products, on_delete: :delete_all)
    end
  end
end
