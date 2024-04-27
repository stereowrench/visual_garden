defmodule VisualGarden.Library.Region do
  use Ecto.Schema
  import Ecto.Changeset

  schema "regions" do
    field :name, :string

    has_many :schedules, VisualGarden.Library.Schedule

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(region, attrs) do
    region
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint([:name])
  end
end
