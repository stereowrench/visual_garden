defmodule VisualGarden.Gardens.PlannerEntry do
  use Ecto.Schema
  import Ecto.Changeset

  schema "planner_entries" do
    field :plant_date, :utc_datetime
    field :mature_date, :utc_datetime
    field :common_name, :string
    belongs_to :bed, VisualGarden.Gardens.Product
    belongs_to :seed, VisualGarden.Gardens.Seed

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(planner_entry, attrs) do
    planner_entry
    |> cast(attrs, [:plant_date, :mature_date, :common_name, :seed_id, :bed_id])
    |> validate_required([:plant_date, :mature_date, :common_name, :seed_id, :bed_id])
  end
end
