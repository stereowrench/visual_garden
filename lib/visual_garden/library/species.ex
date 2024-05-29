defmodule VisualGarden.Library.Species do
  use Ecto.Schema
  import Ecto.Changeset

  schema "species" do
    field :name, :string
    field :cultivar, :string
    field :common_name, :string
    field :genus, :string
    field :variant, :string
    field :season, :string
    field :uuid, Ecto.UUID

    has_many :schedules, VisualGarden.Library.Schedule

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(species, attrs) do
    species
    |> cast(attrs, [:uuid, :name, :genus, :variant, :cultivar, :common_name, :season])
    |> validate_required([:name, :genus])
    |> unique_constraint([:name, :genus, :variant, :cultivar, :season], name: "unique_species")
    |> unique_constraint([:common_name])
  end
end
