defmodule VisualGarden.Repo.Migrations.WizardTables do
  use Ecto.Migration

  def change do
    create table(:wizard_gardens) do
      add :user_id, references(:users, on_delete: :delete_all)
      add :temp_user_id, references(:temp_users, on_delete: :delete_all)
      timestamps(type: :utc_datetime)
    end

    create table(:wizard_beds) do
      add :name, :string
      add :length, :integer
      add :width, :integer

      add :wizard_garden_id, references(:wizard_gardens, on_delete: :delete_all)
      timestamps(type: :utc_datetime)
    end

    create table(:wizard_scaffolds) do
      add :wizard_bed_id, references(:wizard_beds, on_delete: :delete_all)
      add :row, :integer
      add :column, :integer
      timestamps(type: :utc_datetime)
    end

    alter table(:seeds) do
      add :wizard_garden_id, references(:wizard_gardens, on_delete: :delete_all)
    end

    # TODO wizardplannerentry
    create table(:wizard_planner_entries) do
      add :start_plant_date, :date
      add :end_plant_date, :date
      add :nursery_start, :date
      add :nursery_end, :date
      add :days_to_maturity, :integer
      add :days_to_refuse, :integer
      add :common_name, :string
      add :row, :integer
      add :column, :integer
      add :min_lead, :integer
      add :max_lead, :integer

      add :seed_id, references(:seeds, on_delete: :delete_all)
      add :wizard_bed_id, references(:wizard_beds, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end
  end
end
