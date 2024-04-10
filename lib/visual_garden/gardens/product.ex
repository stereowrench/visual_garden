defmodule VisualGarden.Gardens.Product do
  use Ecto.Schema
  import Ecto.Changeset

  schema "products" do
    field :name, :string
    field :type, Ecto.Enum, values: [:growing_media, :fertilizer, :compost, :bed]
    field :garden_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(products, attrs) do
    products
    |> cast(attrs, [:name, :type, :garden_id])
    |> validate_required([:name, :type])
  end
end
