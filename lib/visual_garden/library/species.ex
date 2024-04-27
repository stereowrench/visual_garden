defmodule VisualGarden.Library.Species do
  use Ecto.Schema
  import Ecto.Changeset

  schema "species" do
    field :name, :string
    belongs_to :genus, VisualGarden.Library.Genus

    has_many :schedules, VisualGarden.Library.Schedule

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(species, attrs) do
    species
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
