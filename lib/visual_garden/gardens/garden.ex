defmodule VisualGarden.Gardens.Garden do
  use Ecto.Schema
  import Ecto.Changeset

  schema "gardens" do
    field :name, :string

    field :tz, :string
    has_many :products, VisualGarden.Gardens.Product
    belongs_to :region, VisualGarden.Library.Region

    belongs_to :owner, VisualGarden.Accounts.User
    field :visibility, Ecto.Enum, values: [:public, :private], default: :private

    many_to_many :users, VisualGarden.Accounts.User, join_through: VisualGarden.Gardens.GardenUser

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(garden, attrs) do
    garden
    |> cast(attrs, [:name, :region_id, :tz, :owner_id, :visibility])
    |> cast_assoc(:products)
    |> validate_inclusion(:tz, Tzdata.zone_list())
    |> validate_required([:name, :tz, :region_id, :owner_id, :visibility])
  end
end
