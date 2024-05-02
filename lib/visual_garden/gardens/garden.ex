defmodule VisualGarden.Gardens.Garden do
  use Ecto.Schema
  import Ecto.Changeset

  schema "gardens" do
    field :name, :string

    field :tz, :string
    has_many :products, VisualGarden.Gardens.Product
    belongs_to :region, VisualGarden.Library.Region

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(garden, attrs) do
    garden
    |> cast(attrs, [:name, :region_id, :tz])
    |> cast_assoc(:products)
    |> validate_inclusion(:tz, Tzdata.zone_list())
    |> validate_required([:name, :tz])
  end
end
