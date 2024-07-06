defmodule VisualGarden.Gardens.Seed do
  alias VisualGarden.Wizard.WizardGarden
  alias VisualGarden.Library
  use Ecto.Schema
  import Ecto.Changeset

  schema "seeds" do
    field :name, :string
    field :description, :string
    field :type, Ecto.Enum, values: [:seed, :set, :slip, :transplant, :seed_potato]
    field :any_season, :boolean, default: false
    belongs_to :garden, VisualGarden.Gardens.Garden
    belongs_to :wizard_garden, WizardGarden
    belongs_to :species, VisualGarden.Library.Species
    belongs_to :harvest_species, VisualGarden.Library.Species
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
      :species_id,
      :harvest_species_id,
      :any_season
    ])
    |> validate_required([
      :type,
      :name,
      :description,
      :garden_id,
      :days_to_maturation
    ])
    |> validate_number(:days_to_maturation, greater_than: 0)
    |> adjust_species()
    |> validate_garden()
  end

  def validate_garden(changeset) do
    if get_field(changeset, :garden_id) do
      if get_field(changeset, :wizard_garden_id) do
        add_error(changeset, :wizard_garden_id, "Cannot be set with :garden_id")
      else
        changeset
      end
    else
      if get_field(changeset, :wizard_garden_id) do
        changeset
      else
        add_error(
          changeset,
          :wizard_garden_id,
          "Either :garden_id or :wizard_garden_id must be set"
        )
      end
    end
  end

  defp adjust_species(cs) do
    if get_field(cs, :any_season) do
      as = Library.get_any_season()

      if get_field(cs, :species_id) do
        cs
        |> put_change(:harvest_species_id, get_field(cs, :species_id))
        |> put_change(:species_id, as.id)
      else
        cs
        |> put_change(:species_id, as.id)
      end
    else
      sid = get_field(cs, :harvest_species_id)

      if sid do
        put_change(cs, :species_id, sid)
      else
        put_change(cs, :harvest_species_id, get_field(cs, :species_id))
      end
    end
  end
end
