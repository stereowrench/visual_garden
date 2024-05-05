defmodule VisualGarden.Gardens.Seed do
  use Ecto.Schema
  import Ecto.Changeset

  schema "seeds" do
    field :name, :string
    field :description, :string
    belongs_to :garden, VisualGarden.Gardens.Garden

    field :days_to_maturation, :integer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(seed, attrs) do
    seed
    |> cast(attrs, [:name, :description, :garden_id, :days_to_maturation])
    |> validate_required([:name, :description, :garden_id, :days_to_maturation])
    |> validate_number(:days_to_maturation, min: 0)
  end
end
