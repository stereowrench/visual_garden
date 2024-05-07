defmodule VisualGarden.Gardens.PlannerEntry do
  use Ecto.Schema
  import Ecto.Changeset

  schema "planner_entries" do
    field :start_plant_date, :utc_datetime
    field :end_plant_date, :utc_datetime
    field :days_to_maturity, :integer
    field :days_to_refuse, :integer
    field :common_name, :string
    belongs_to :bed, VisualGarden.Gardens.Product
    belongs_to :seed, VisualGarden.Gardens.Seed

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(planner_entry, attrs) do
    planner_entry
    |> cast(attrs, [
      :start_plant_date,
      :end_plant_date,
      :days_to_maturity,
      :days_to_refuse,
      :common_name,
      :seed_id,
      :bed_id
    ])
    |> validate_required([
      :start_plant_date,
      :end_plant_date,
      :days_to_maturity,
      :days_to_refuse,
      :common_name,
      :seed_id,
      :bed_id
    ])
  end
end
