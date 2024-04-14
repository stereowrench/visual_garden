defmodule VisualGarden.Gardens.Plant do
  use Ecto.Schema
  import Ecto.Changeset

  schema "plants" do
    belongs_to :seed, VisualGarden.Gardens.Seed
    belongs_to :product, VisualGarden.Gardens.Product

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(plant, attrs) do
    cl =
      plant
      |> cast(attrs, [:product_id, :seed_id])
      |> cast_assoc(:seed, with: &VisualGarden.Gardens.Seed.changeset/2)
      |> cast_assoc(:product, with: &VisualGarden.Gardens.Product.changeset/2)

    cl =
      unless attrs["seed"] || attrs[:seed] do
        validate_required(cl, [:seed_id])
      else
        cl
      end

    unless attrs["product"] || attrs[:product] do
      validate_required(cl, [:product_id])
    else
      cl
    end
  end
end
