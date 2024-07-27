defmodule VisualGarden.Library.Schedule do
  use Ecto.Schema
  import Ecto.Changeset

  schema "schedules" do
    field :label, :string
    field :start_month, :integer
    field :start_day, :integer
    field :end_month, :integer
    field :end_day, :integer
    field :end_month_adjusted, :integer
    field :nursery_lead_weeks_min, :integer
    field :nursery_lead_weeks_max, :integer

    field :plantable_types, {:array, :string}

    belongs_to :region, VisualGarden.Library.Region

    many_to_many :species, VisualGarden.Library.Species,
      join_through: VisualGarden.Library.SpeciesSchedule

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(schedule, attrs) do
    schedule
    |> cast(attrs, [
      :start_month,
      :label,
      :plantable_types,
      :start_day,
      :end_month,
      :end_day,
      :region_id,
      :nursery_lead_weeks_min,
      :nursery_lead_weeks_max
    ])
    |> validate_required([:start_month, :start_day, :end_month, :end_day, :region_id])
    |> validate_subset(:plantable_types, ["transplant", "seed", "slip", "set", "seed_potato"])
    |> add_end_month_adjusted()
  end

  defp add_end_month_adjusted(changeset) do
    if changeset.valid? do
      mo = get_field(changeset, :end_month)
      put_change(changeset, :end_month_adjusted, mo + 12)
    else
      changeset
    end
  end
end
