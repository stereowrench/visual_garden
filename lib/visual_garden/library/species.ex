defmodule VisualGarden.Library.Species do
  use Ecto.Schema
  import Ecto.Changeset

  schema "species" do
    field :name, :string
    field :cultivar, :string
    belongs_to :genus, VisualGarden.Library.Genus

    has_many :schedules, VisualGarden.Library.Schedule

    timestamps(type: :utc_datetime)
  end

  @spec changeset(
          {map(), map()}
          | %{
              :__struct__ => atom() | %{:__changeset__ => map(), optional(any()) => any()},
              optional(atom()) => any()
            },
          :invalid | %{optional(:__struct__) => none(), optional(atom() | binary()) => any()}
        ) :: Ecto.Changeset.t()
  @doc false
  def changeset(species, attrs) do
    species
    |> cast(attrs, [:name, :genus_id, :cultivar])
    |> validate_required([:name, :genus_id])
    |> unique_constraint([:name, :genus_id, :cultivar])
  end
end
