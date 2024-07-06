defmodule VisualGarden.Wizard.TempUser do
  alias VisualGarden.Wizard.WizardGarden
  use Ecto.Schema
  import Ecto.Changeset

  schema "temp_users" do
    has_many :wizard_gardens, WizardGarden
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(temp_user, attrs) do
    temp_user
    |> cast(attrs, [])
    |> validate_required([])
  end
end
