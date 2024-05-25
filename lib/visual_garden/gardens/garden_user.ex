defmodule VisualGarden.Gardens.GardenUser do
  use Ecto.Schema
  import Ecto.Changeset

  schema "garden_users" do
    belongs_to :garden, VisualGarden.Gardens.Garden
    belongs_to :user, VisualGarden.Accounts.User
    timestamps(type: :utc_datetime)
  end

  def changeset(cs, attrs \\ %{}) do
    cs
    |> cast(attrs, [:garden_id, :user_id])
    |> validate_required([:garden_id, :user_id])
  end
end
