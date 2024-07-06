defmodule VisualGarden.Wizard.WizardGarden do
  alias VisualGarden.Wizard.WizardBed
  alias VisualGarden.Wizard.TempUser
  alias VisualGarden.Accounts.User
  use Ecto.Schema
  import Ecto.Changeset

  schema "wizard_gardens" do
    belongs_to :user, User
    belongs_to :temp_user, TempUser
    has_many :wizard_beds, WizardBed
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(garden, attrs) do
    garden
    |> cast(attrs, [:user_id, :temp_user_id])
    |> validate_required([])
    |> validate_user_info()
  end

  def validate_user_info(changeset) do
    if _ = get_field(changeset, :user_id) do
      if _ = get_field(changeset, :temp_user_id) do
        add_error(changeset, :temp_user_id, "temp_user_id cannot be set when user_id is set")
      else
        changeset
      end
    else
      unless _ = get_field(changeset, :temp_user_id) do
        changeset
        |> add_error(:temp_user_id, "user_id and temp_user_id cannot both be nil")
        |> add_error(:user_id, "user_id and temp_user_id cannot both be nil")
      else
        changeset
      end
    end
  end
end
