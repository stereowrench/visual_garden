defmodule VisualGarden.Gardens.Seed do
  use Ecto.Schema
  import Ecto.Changeset

  schema "seeds" do
    field :name, :string
    field :description, :string
    field :type, Ecto.Enum, values: [:seed, :set, :slip, :transplant, :seed_potato]
    belongs_to :garden, VisualGarden.Gardens.Garden
    belongs_to :species, VisualGarden.Library.Species
    belongs_to :library_seed, VisualGarden.Library.LibrarySeed

    field :days_to_maturation, :integer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(seed, attrs) do
    seed
    |> cast(attrs, [
      :library_seed_id,
      :type,
      :name,
      :description,
      :garden_id,
      :days_to_maturation,
      :species_id
    ])
    |> validate_required([
      :type,
      :name,
      :description,
      :garden_id,
      :days_to_maturation
    ])
    |> validate_number(:days_to_maturation, greater_than: 0)
  end
end
