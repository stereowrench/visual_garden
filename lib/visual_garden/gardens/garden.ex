defmodule VisualGarden.Gardens.Garden do
  use Ecto.Schema
  import Ecto.Changeset

  schema "gardens" do
    field :name, :string

    has_many :products, VisualGarden.Gardens.Product
    belongs_to :region, VisualGarden.Library.Region

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(garden, attrs) do
    garden
    |> cast(attrs, [:name, :region_id])
    |> cast_assoc(:products)
    |> validate_required([:name])
  end
end
