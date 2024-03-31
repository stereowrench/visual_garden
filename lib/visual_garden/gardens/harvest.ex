defmodule VisualGarden.Gardens.Harvest do
  use Ecto.Schema
  import Ecto.Changeset

  schema "harvests" do
    field :quantity, :decimal
    field :units, :string
    field :plant_id, :id
    field :product_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(harvest, attrs) do
    harvest
    |> cast(attrs, [:quantity, :units])
    |> validate_required([:quantity, :units])
  end
end
