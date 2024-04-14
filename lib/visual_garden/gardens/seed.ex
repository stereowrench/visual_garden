defmodule VisualGarden.Gardens.Seed do
  use Ecto.Schema
  import Ecto.Changeset

  schema "seeds" do
    field :name, :string
    field :description, :string
    belongs_to :garden, VisualGarden.Gardens.Garden

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(seed, attrs) do
    seed
    |> cast(attrs, [:name, :description, :garden_id])
    |> validate_required([:name, :description, :garden_id])
  end
end
