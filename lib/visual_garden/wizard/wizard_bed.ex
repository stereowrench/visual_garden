defmodule VisualGarden.Wizard.WizardBed do
  alias VisualGarden.Wizard.WizardPlannerEntry
  alias VisualGarden.Gardens.Product
  alias VisualGarden.Wizard.WizardGarden
  alias VisualGarden.Wizard.Scaffold
  use Ecto.Schema
  import Ecto.Changeset

  schema "wizard_beds" do
    field :name, :string
    field :length, :integer
    field :width, :integer

    has_many :scaffolds, WizardScaffold
    belongs_to :wizard_garden, WizardGarden

    has_many :planner_entries, WizardPlannerEntry

    belongs_to :bed, Product
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(bed, attrs) do
    bed
    |> cast(attrs, [])
    |> validate_required([])
  end
end
