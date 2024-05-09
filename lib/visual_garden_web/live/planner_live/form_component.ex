defmodule VisualGardenWeb.PlannerLive.FormComponent do
  alias VisualGarden.Gardens.PlannerEntry
  alias VisualGarden.Gardens
  use VisualGardenWeb, :live_component

  alias VisualGarden.Library

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Planner Entry
      </.header>

      <.simple_form
        for={@form}
        id="planner-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field="Plantable"
          name="species"
          type="select"
          label="Select Species"
          options={@species}
          value=""
        />
        <%= unless @species_selected == "" do %>
          <.input
            field={@form[:start_plant_date]}
            phx-update="ignore"
            type="date"
            label="Earliest Plant"
          />
          <.input field={@form[:end_plant_date]} phx-update="ignore" type="date" label="Latest Plant" />
          <.input field={@form[:days_to_maturity]} type="number" label="Days to Maturity" />
          <.input field={@form[:days_to_refuse]} type="number" label="Days to Refuse" />
        <% end %>
        <:actions>
          <.button phx-disable-with="Saving...">Save planner</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    plantables_parsed =
      assigns.plantables
      |> Enum.group_by(& &1.schedule.species.common_name)

    # garden
    # bed
    # extent_dates
    changeset = Gardens.change_planner_entry(%PlannerEntry{})
    {square, ""} = Integer.parse(assigns.square)

    species =
      ["Choose a species": nil] ++
        (Map.keys(plantables_parsed)
         |> Enum.map(&{&1, &1}))

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:row, trunc((square - 1) / assigns.bed.length))
     |> assign(:species, species)
     |> assign(:species_selected, "")
     |> assign(:plantables_parsed, plantables_parsed)
     |> assign(:column, rem(square - 1, assigns.bed.length))
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"planner_entry" => planner_params}, socket) do
    changeset =
      %PlannerEntry{}
      |> Library.change_planner_entry(planner_params)
      |> Map.put(:action, :validate)

    {:noreply, socket |> assign_form(changeset)}
  end

  def handle_event("validate", %{"species" => species}, socket) do
    socket.assigns.plantables_parsed[species]
    |> IO.inspect()

    {:noreply, socket |> assign(:species_selected, species)}
  end

  def handle_event("save", %{"planner" => planner_params}, socket) do
    save_planner(socket, socket.assigns.action, planner_params)
  end

  defp save_planner(socket, :edit, planner_params) do
  end

  defp save_planner(socket, :new, planner_params) do
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
