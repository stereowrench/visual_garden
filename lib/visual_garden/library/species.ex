defmodule VisualGarden.Library.Species do
  use Ecto.Schema
  import Ecto.Changeset

  schema "species" do
    field :name, :string
    field :cultivar, :string
    field :common_name, :string
    field :genus, :string
    field :variant, :string

    has_many :schedules, VisualGarden.Library.Schedule

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(species, attrs) do
    species
    |> cast(attrs, [:name, :genus, :cultivar, :common_name])
    |> validate_required([:name, :genus])
    |> unique_constraint([:name, :genus, :variant, :cultivar])
  end
end
