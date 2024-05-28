defmodule VisualGarden.Library.LibrarySeed do
  use Ecto.Schema
  import Ecto.Changeset

  schema "library_seeds" do
    field :type, Ecto.Enum, values: [:seed, :set, :slip, :transplant]
    field :days_to_maturation, :integer
    field :manufacturer, :string
    field :name, :string
    belongs_to :species, VisualGarden.Library.Species

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(seeds, attrs) do
    seeds
    |> cast(attrs, [:type, :name, :days_to_maturation, :manufacturer, :species_id])
    |> validate_required([:type, :days_to_maturation, :manufacturer, :species_id])
  end
end
