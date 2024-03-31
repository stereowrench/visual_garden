defmodule VisualGarden.Gardens.Seed do
  use Ecto.Schema
  import Ecto.Changeset

  schema "seeds" do
    field :name, :string
    field :description, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(seed, attrs) do
    seed
    |> cast(attrs, [:name, :description])
    |> validate_required([:name, :description])
  end
end
