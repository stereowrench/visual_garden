defmodule VisualGarden.Gardens.EventLog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "event_logs" do
    field :event_time, :utc_datetime
    field :event_time_hidden, :utc_datetime, virtual: true

    field :event_type, Ecto.Enum,
      values: [
        :water,
        :humidity,
        :mow,
        :trim,
        :till,
        :transfer,
        :harvest,
        :transfer_harvest,
        :plant
      ]

    field :humidity, :integer
    field :mowed, :boolean, default: false
    field :mow_depth_in, :decimal
    field :till_depth_in, :decimal
    field :transferred_amount, :decimal
    field :trimmed, :boolean, default: false

    field :transfer_units, Ecto.Enum,
      values: [
        :cuft,
        :scoops,
        :Quarts
      ]

    belongs_to :transferred_to, VisualGarden.Gardens.Product
    belongs_to :transferred_from, VisualGarden.Gardens.Product
    field :transplanted_to, :id
    field :transplanted_from, :id
    field :planted_in_id, :id
    belongs_to :product, VisualGarden.Gardens.Product
    belongs_to :plant, VisualGarden.Gardens.Plant
    field :harvest_id, :id
    field :harvest_transfer_from, :id
    field :harvest_transfer_to, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset_water(event_log, attrs) do
    event_log
    |> cast(attrs, [
      :event_type,
      :event_time,
      :product_id
    ])
    |> validate_required([:event_time, :product_id])
    |> validate_inclusion(:event_type, [:water])
  end

  @doc false
  def changeset_tilled(event_log, attrs) do
    event_log
    |> cast(attrs, [
      :event_type,
      :product_id,
      :event_time,
      :till_depth_in
    ])
    |> validate_required([:event_time, :product_id])
    |> validate_inclusion(:event_type, [:till])
  end

  @doc false
  def changeset_transfer(event_log, attrs) do
    event_log
    |> cast(attrs, [
      :event_type,
      :product_id,
      :event_time,
      :transferred_to_id,
      :transferred_from_id,
      :transferred_amount,
      :transfer_units
    ])
    |> validate_required([
      :product_id,
      :event_time,
      :event_type,
      :transferred_to_id,
      :transferred_from_id
    ])
    |> validate_inclusion(:event_type, [:transfer])
  end

  @doc false
  def changeset_plant(event_log, attrs) do
    event_log
    |> cast(attrs, [
      :event_type,
      :product_id,
      :plant_id,
      :event_time,
    ])
    |> validate_required([
      :product_id,
      :plant_id,
      :event_type,
      :event_time,
    ])
    |> validate_inclusion(:event_type, [:plant])
  end

  @doc false
  def changeset(event_log, attrs) do
    event_log
    |> cast(attrs, [
      :event_type,
      :mowed,
      :mow_depth_in,
      :till_depth_in,
      :transferred_amount,
      :trimmed,
      :transfer_units
    ])
    |> validate_required([
      :event_type,
      :mowed,
      :mow_depth_in,
      :till_depth_in,
      :transferred_amount,
      :trimmed,
      :transfer_units
    ])
  end
end
