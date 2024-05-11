defmodule VisualGarden.Gardens.NurseryEntry do
  alias VisualGarden.Gardens.Garden
  alias VisualGarden.Gardens.Seed
  alias VisualGarden.Gardens.PlannerEntry
  use Ecto.Schema
  import Ecto.Changeset

  schema "nursery_entries" do
    field :sow_date, :date
    belongs_to :planner_entry, PlannerEntry
    belongs_to :seed, Seed
    belongs_to :garden, Garden

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(nursery_entry, attrs) do
    nursery_entry
    |> cast(attrs, [:sow_date, :planner_entry_id, :seed_id, :garden_id])
    |> validate_required([:sow_date, :garden_id])
  end
end
