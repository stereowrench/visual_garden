defmodule VisualGarden.Gardens.PlannerEntry do
  alias VisualGarden.Gardens
  use Ecto.Schema
  import Ecto.Changeset

  schema "planner_entries" do
    field :start_plant_date, :date
    field :end_plant_date, :date
    field :nursery_start, :date
    field :nursery_end, :date
    field :days_to_maturity, :integer
    field :days_to_refuse, :integer
    field :common_name, :string
    field :row, :integer
    field :column, :integer
    field :min_lead, :integer
    field :max_lead, :integer
    belongs_to :bed, VisualGarden.Gardens.Product
    belongs_to :seed, VisualGarden.Gardens.Seed
    has_one :nursery_entry, VisualGarden.Gardens.NurseryEntry
    belongs_to :plant, Gardens.Plant

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(planner_entry, attrs, garden) do
    planner_entry
    |> cast(attrs, [
      :nursery_start,
      :nursery_end,
      :start_plant_date,
      :end_plant_date,
      :days_to_maturity,
      :days_to_refuse,
      :common_name,
      :seed_id,
      :bed_id,
      :row,
      :column,
      :plant_id,
      :min_lead,
      :max_lead
    ])
    |> validate_required([
      :start_plant_date,
      :end_plant_date,
      :days_to_maturity,
      :common_name,
      :seed_id,
      :bed_id,
      :row,
      :column
    ])
    |> validate_change(:bed_id, fn :bed_id, bid ->
      bed = Gardens.get_product!(bid)

      if bed.garden_id != garden.id do
        [bed_id: "Bed is not in the garden"]
      else
        []
      end
    end)
    |> validate_change(:seed_id, fn :seed_id, sid ->
      seed = Gardens.get_seed!(sid)

      if seed.garden_id != garden.id do
        [seed_id: "Seed not in the garden"]
      else
        []
      end
    end)
  end
end
