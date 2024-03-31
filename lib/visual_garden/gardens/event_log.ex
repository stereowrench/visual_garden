defmodule VisualGarden.Gardens.EventLog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "event_logs" do
    field :event_type, Ecto.Enum, values: [:water, :humidity, :mow, :trim, :till, :transfer, :harvest, :transfer_harvest, :plant]
    field :watered, :boolean, default: false
    field :humidity, :integer
    field :mowed, :boolean, default: false
    field :mow_depth_in, :decimal
    field :tilled, :boolean, default: false
    field :till_depth_in, :decimal
    field :transferred_amount, :decimal
    field :trimmed, :boolean, default: false
    field :transfer_units, :string
    field :transferred_to, :id
    field :transferred_from, :id
    field :transplanted_to, :id
    field :transplanted_from, :id
    field :planted_in_id, :id
    field :product_id, :id
    field :plant_id, :id
    field :harvest_id, :id
    field :harvest_transfer_from, :id
    field :harvest_transfer_to, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(event_log, attrs) do
    event_log
    |> cast(attrs, [:event_type, :watered, :humidity, :mowed, :mow_depth_in, :tilled, :till_depth_in, :transferred_amount, :trimmed, :transfer_units])
    |> validate_required([:event_type, :watered, :humidity, :mowed, :mow_depth_in, :tilled, :till_depth_in, :transferred_amount, :trimmed, :transfer_units])
  end
end
