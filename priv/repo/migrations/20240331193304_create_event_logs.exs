defmodule VisualGarden.Repo.Migrations.CreateEventLogs do
  use Ecto.Migration

  def change do
    create table(:event_logs) do
      add :event_type, :string
      add :watered, :boolean, default: false, null: false
      add :humidity, :integer
      add :mowed, :boolean, default: false, null: false
      add :mow_depth_in, :decimal
      add :tilled, :boolean, default: false, null: false
      add :till_depth_in, :decimal
      add :transferred_amount, :decimal
      add :trimmed, :boolean, default: false, null: false
      add :transfer_units, :string
      add :transferred_to, references(:products, on_delete: :nothing)
      add :transferred_from, references(:products, on_delete: :nothing)
      add :transplanted_to, references(:products, on_delete: :nothing)
      add :transplanted_from, references(:products, on_delete: :nothing)
      add :planted_in_id, references(:products, on_delete: :nothing)
      add :product_id, references(:products, on_delete: :nothing)
      add :plant_id, references(:plants, on_delete: :nothing)
      add :harvest_id, references(:harvests, on_delete: :nothing)
      add :harvest_transfer_from, references(:harvests, on_delete: :nothing)
      add :harvest_transfer_to, references(:harvests, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:event_logs, [:transferred_to])
    create index(:event_logs, [:transferred_from])
    create index(:event_logs, [:transplanted_to])
    create index(:event_logs, [:transplanted_from])
    create index(:event_logs, [:planted_in_id])
    create index(:event_logs, [:product_id])
    create index(:event_logs, [:plant_id])
    create index(:event_logs, [:harvest_id])
    create index(:event_logs, [:harvest_transfer_from])
    create index(:event_logs, [:harvest_transfer_to])
  end
end
