defmodule VisualGarden.Gardens.Harvest do
  use Ecto.Schema
  import Ecto.Changeset

  @units [:Quarts, :cuft]

  schema "harvests" do
    field :quantity, :decimal
    field :units, Ecto.Enum, values: @units
    field :plant_id, :id
    field :product_id, :id

    timestamps(type: :utc_datetime)
  end

  def unit_options do
    @units
  end

  @doc false
  def changeset(harvest, attrs) do
    harvest
    |> cast(attrs, [:quantity, :units])
    |> validate_required([:quantity, :units])
  end
end
