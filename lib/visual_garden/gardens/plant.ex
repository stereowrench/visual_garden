defmodule VisualGarden.Gardens.Plant do
  use Ecto.Schema
  import Ecto.Changeset

  schema "plants" do

    field :seed_id, :id
    field :product_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(plant, attrs) do
    plant
    |> cast(attrs, [])
    |> validate_required([])
  end
end
