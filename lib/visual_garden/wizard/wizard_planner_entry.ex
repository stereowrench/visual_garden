defmodule VisualGarden.Wizard.WizardPlannerEntry do
  use Ecto.Schema
  import Ecto.Changeset

  schema "wizard_planner_entry" do
    field :start_plant_date, :date
    field :end_plant_date, :date
    field :nursery_start, :date
    field :nursery_end, :date
    field :days_to_maturity, :integer
    field :days_to_refuse, :integer
    field :common_name, :string
    field :row, :integer
    field :column, :integer
    field :min_lead, :integer
    field :max_lead, :integer

    belongs_to :seed, VisualGarden.Gardens.Seed
    belongs_to :wizard_bed, VisualGarden.Wizard.WizardBed

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(planner_entry, attrs) do
    planner_entry
    |> cast(attrs, [])
    |> validate_required([])
  end
end
