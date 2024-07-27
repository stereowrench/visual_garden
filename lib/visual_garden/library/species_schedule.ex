defmodule VisualGarden.Library.SpeciesSchedule do
  use Ecto.Schema
  import Ecto.Changeset

  schema "species_schedules" do
    belongs_to :species, VisualGarden.Library.Species
    belongs_to :schedule, VisualGarden.Library.Schedule
    timestamps(type: :utc_datetime)
  end

  def changeset(cs, attrs \\ %{}) do
    cs
    |> cast(attrs, [:species_id, :schedule_id])
    |> validate_required([:species_id, :schedule_id])
    |> unique_constraint([:schedule_id, :species_id])
  end
end
