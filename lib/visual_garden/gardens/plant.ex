defmodule VisualGarden.Gardens.Plant do
  use Ecto.Schema
  import Ecto.Changeset

  schema "plants" do
    belongs_to :seed, VisualGarden.Gardens.Seed
    belongs_to :product, VisualGarden.Gardens.Product
    field :name, :string
    field :qty, :integer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(plant, attrs) do
    cl =
      plant

    valid_attrs = [:name, :qty]

    valid_attrs =
      if attrs["seed_id"] == "-1" or attrs[:seed_id] == "-1" do
        valid_attrs
      else
        valid_attrs ++ [:seed_id]
      end

    valid_attrs =
      if attrs["product_id"] == "-1" or attrs[:product_id] == "-1" do
        valid_attrs
      else
        valid_attrs ++ [:product_id]
      end

    cl =
      cl
      |> cast(attrs, valid_attrs)
      |> validate_number(:qty, greater_than_or_equal_to: 1)

    cl =
      cl
      |> validate_required([:name])
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
