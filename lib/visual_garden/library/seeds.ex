defmodule VisualGarden.Library.Seeds do
  use Ecto.Schema
  import Ecto.Changeset

  schema "library_seeds" do
    field :type, Ecto.Enum, values: [:transplant, :seed, :set, :slip]
    field :days_to_maturation, :integer
    field :manufacturer, :string
    belongs_to :species, VisualGarden.Library.Species

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(seeds, attrs) do
    seeds
    |> cast(attrs, [:type, :days_to_maturation, :manufacturer, :species_id])
    |> validate_required([:type, :days_to_maturation, :manufacturer, :species_id])
  end
end
