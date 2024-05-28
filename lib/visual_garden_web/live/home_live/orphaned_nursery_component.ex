defmodule VisualGardenWeb.HomeLive.OrphanedNurseryComponent do
  alias VisualGardenWeb.PlannerLive.GraphComponent
  alias VisualGarden.MyDateTime
  alias VisualGarden.Authorization.UnauthorizedError
  alias VisualGarden.Repo
  alias VisualGarden.Gardens
  alias VisualGarden.Planner
  alias VisualGarden.Authorization
  use VisualGardenWeb, :live_component

  import Ecto.Changeset

  defmodule OrphanSchema do
    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
      field :bed_id, :integer
      field :refuse_date, :date
      field :square, :integer
    end

    @params [:bed_id, :refuse_date, :square]

    def changeset(schema, attrs \\ %{}) do
      schema
      |> cast(attrs, @params)
      |> validate_required(@params)
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.simple_form
        for={@form}
        id="orphan-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:bed_id]}
          type="select"
          label="Bed"
          prompt="Choose a bed"
          options={@beds}
        />
        <%= if @form[:bed_id].value do %>
          <.input
            field={@form[:square]}
            type="select"
            label="Square"
            prompt="Choose a square"
            options={@squares}
          />
        <% end %>

        <%= if @form[:square].value not in [nil, ""] do %>
          <.input
            field={@form[:refuse_date]}
            type="date"
            label="Refuse date"
            min={@start_refuse_date}
            max={@end_refuse_date}
          />
        <% end %>
        <:actions>
          <.button phx-disable-with="Saving...">Plant</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    Authorization.authorize_garden_modify(assigns.nursery_entry.garden_id, assigns.current_user)
    changeset = OrphanSchema.changeset(%OrphanSchema{})

    socket = assign(socket, garden: Gardens.get_garden!(assigns.nursery_entry.garden_id))

    date =
      Timex.shift(assigns.nursery_entry.sow_date,
        days: assigns.nursery_entry.seed.days_to_maturation
      )

    open_slots =
      Planner.get_open_slots(socket.assigns.garden, date)

    beds_map =
      open_slots
      |> Enum.group_by(&{&1.bed_name, &1.bed_id})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:beds, Map.keys(beds_map))
     |> assign(:slots_map, open_slots)
     |> assign(
       :start_refuse_date,
       Timex.shift(assigns.nursery_entry.sow_date,
         days: assigns.nursery_entry.seed.days_to_maturation
       )
     )
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"orphan_schema" => oschema}, socket) do
    changeset =
      %OrphanSchema{}
      |> OrphanSchema.changeset(oschema)
      |> Map.put(:action, :validate)

    if oschema["bed_id"] not in ["", nil] do
      grouped =
        socket.assigns.slots_map
        |> Enum.group_by(&to_string(&1.bed_id))

      for_bed = grouped[to_string(oschema["bed_id"])]
      bed = Gardens.get_product!(oschema["bed_id"])

      squares =
        for_bed
        |> Enum.map(fn
          %{row: row, col: column} ->
            [
              key: "#{row}, #{column}",
              value: GraphComponent.bed_square(%{row: row, column: column}, bed)
            ]
        end)

      end_date =
        if oschema["square"] not in [nil, ""] do
          {row, col} = Planner.parse_square(oschema["square"], bed)
          en = for_bed |> Enum.find(&(&1.row == row && &1.col == col))
          en.end_date
        else
          nil
        end

      {:noreply,
       socket
       |> assign(:squares, squares)
       |> assign(:end_refuse_date, end_date)
       |> assign_form(changeset)}
    else
      {:noreply, socket |> assign_form(changeset)}
    end
  end

  @impl true
  def handle_event("save", %{"orphan_schema" => oschema}, socket) do
    Authorization.authorize_garden_modify(
      socket.assigns.nursery_entry.garden_id,
      socket.assigns.current_user
    )

    changeset =
      %OrphanSchema{}
      |> OrphanSchema.changeset(oschema)
      |> Map.put(:action, :validate)

    if changeset.valid? do
      refuse_date = get_field(changeset, :refuse_date)
      square = get_field(changeset, :square)
      bid = get_field(changeset, :bed_id)
      bed = Gardens.get_product!(bid)

      {row, col} = Planner.parse_square(to_string(square), bed)

      if Gardens.get_product!(bid).garden_id != socket.assigns.garden.id do
        raise UnauthorizedError
      end

      {:ok, _} =
        Repo.transaction(fn ->
          {:ok, pe} =
            Planner.create_planner_entry_for_orphaned_nursery(
              socket.assigns.nursery_entry,
              socket.assigns.garden,
              row,
              col,
              bid,
              refuse_date
            )

          {:ok, plant} =
            Gardens.create_plant(%{
              garden_id: socket.assigns.garden.id,
              name: "#{socket.assigns.nursery_entry.seed.name} - #{MyDateTime.utc_today()}",
              qty: 1,
              row: row,
              column: col,
              product_id: bed.id
            })

          {:ok, _} =
            Gardens.update_nursery_entry(socket.assigns.nursery_entry, %{planner_entry_id: pe.id})

          {:ok, _} = Planner.set_planner_entry_plant(pe, plant.id, socket.assigns.garden)
        end)

      {:noreply,
       socket
       |> put_notification(Normal.new(:success, "Entry created!"))
       |> push_patch(to: socket.assigns.patch)}
    else
      {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
