defmodule VisualGarden.Library.Genus do
  use Ecto.Schema
  import Ecto.Changeset

  schema "genera" do
    field :name, :string
    has_many :species, VisualGarden.Library.Species

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(genus, attrs) do
    genus
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
