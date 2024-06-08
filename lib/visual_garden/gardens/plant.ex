defmodule VisualGarden.Gardens.Plant do
  use Ecto.Schema
  import Ecto.Changeset

  schema "plants" do
    belongs_to :seed, VisualGarden.Gardens.Seed
    belongs_to :product, VisualGarden.Gardens.Product
    field :name, :string
    field :qty, :integer

    field :row, :integer
    field :column, :integer
    field :archived, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(plant, attrs) do
    plant
    |> cast(attrs, [:name, :qty, :row, :column, :seed_id, :product_id, :archived])
    |> validate_number(:qty, greater_than_or_equal_to: 1)
    |> validate_seed()
    |> validate_plant()
    |> validate_required([:name, :qty, :row, :column])
    |> cast_assoc(:seed, with: &VisualGarden.Gardens.Seed.changeset/2)
    |> cast_assoc(:product, with: &VisualGarden.Gardens.Product.changeset/2)
  end

  defp validate_seed(cs) do
    case get_field(cs, :seed_id) do
      -1 ->
        delete_change(cs, :seed_id)

      _ ->
        cs
    end
  end

  defp validate_plant(cs) do
    case get_field(cs, :product_id) do
      -1 ->
        cs
        |> delete_change(:product_id)

      _ ->
        if get_change(cs, :product) == nil do
          validate_required(cs, :product_id)
        else
          cs
        end
    end
  end
end
