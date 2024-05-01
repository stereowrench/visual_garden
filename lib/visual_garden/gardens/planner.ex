defmodule VisualGarden.Gardens.Planner do
  use Ecto.Schema
  import Ecto.Changeset

  schema "planners" do
    field :garden_id, :id
    has_many :entries, VisualGarden.Gardens.PlannerEntry

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(planner, attrs) do
    planner
    |> cast(attrs, [])
    |> validate_required([])
  end
end
