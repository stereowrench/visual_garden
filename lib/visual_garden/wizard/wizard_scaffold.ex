defmodule VisualGarden.Wizard.WizardScaffold do
  use Ecto.Schema
  import Ecto.Changeset

  schema "wizard_scaffolds" do
    field :row, :integer
    field :column, :integer
    belongs_to :wizard_bed, VisualGarden.Wizard.WizardBed
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(scaffold, attrs) do
    scaffold
    |> cast(attrs, [])
    |> validate_required([])
  end
end
