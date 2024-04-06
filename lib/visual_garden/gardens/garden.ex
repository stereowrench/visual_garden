defmodule VisualGarden.Gardens.Garden do
  use Ecto.Schema
  import Ecto.Changeset

  schema "gardens" do
    field :name, :string

    has_many :products, VisualGarden.Gardens.Product

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(garden, attrs) do
    garden
    |> cast(attrs, [:name])
    |> cast_assoc(:products)
    |> validate_required([:name])
  end
end
