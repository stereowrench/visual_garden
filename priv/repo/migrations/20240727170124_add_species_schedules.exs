defmodule VisualGarden.Repo.Migrations.AddSpeciesSchedules do
  use Ecto.Migration

  def up do
    create table(:species_schedules) do
      add :species_id, references(:species, on_delete: :delete_all)
      add :schedule_id, references(:schedules, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:species_schedules, [:species_id, :schedule_id])

    flush()

    execute """
    INSERT INTO species_schedules (species_id, schedule_id, inserted_at, updated_at)
    SELECT species_id, id, NOW() as inserted_at, NOW() as updated_at
    FROM schedules
    """

    flush()

    alter table(:schedules) do
      remove :species_id
    end
  end
end
