defmodule VisualGarden.Gardens.Product do
  use Ecto.Schema
  import Ecto.Changeset

  schema "products" do
    field :name, :string
    field :type, Ecto.Enum, values: [:growing_media, :fertilizer, :compost, :bed]
    field :garden_id, :id

    field :length, :integer
    field :width, :integer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(products, attrs) do
    products
    |> cast(attrs, [:name, :type, :garden_id, :length, :width])
    |> validate_required([:name, :type, :garden_id])
    |> maybe_require_dimensions()
  end

  defp maybe_require_dimensions(cs) do
    case get_field(cs, :type) do
      :bed ->
        cs
        |> validate_required([:length, :width])

      _ ->
        cs
    end
  end

  def friendly_type(:growing_media), do: "Growing Media"
  def friendly_type(:bed), do: "Bed"
  def friendly_type(:compost), do: "Compost"
  def friendly_type(:fertilizer), do: "Fertilizer"
end
