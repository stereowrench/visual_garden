defmodule VisualGarden.Library.Schedule do
  use Ecto.Schema
  import Ecto.Changeset

  schema "schedules" do
    field :start_month, :integer
    field :start_day, :integer
    field :end_month, :integer
    field :end_day, :integer
    field :end_month_adjusted, :integer

    belongs_to :region, VisualGarden.Library.Region
    belongs_to :species, VisualGarden.Library.Species

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(schedule, attrs) do
    schedule
    |> cast(attrs, [:start_month, :start_day, :end_month, :end_day, :end_month_adjusted])
    |> validate_required([:start_month, :start_day, :end_month, :end_day])
    |> add_end_month_adjusted()
  end

  defp add_end_month_adjusted(changeset) do
    if changeset.valid? do
      mo = get_change(changeset, :end_month)
      put_change(changeset, :end_month_adjusted, mo + 12)
    else
      changeset
    end
  end
end