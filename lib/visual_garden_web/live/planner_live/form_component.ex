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
        <%!-- List  --%>
        <.input field={@form[:plant_date]} phx-hook="DateSelect" phx-update="ignore" type="date" label="Name" />
        <:actions>
          <.button phx-disable-with="Saving...">Save planner</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    changeset = Gardens.change_planner_entry(%PlannerEntry{})
    {square, ""} = Integer.parse(assigns.square)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:row, trunc((square - 1) / assigns.bed.length))
     |> assign(:column, rem(square - 1, assigns.bed.length))
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"planner_entry" => planner_params}, socket) do
    changeset =
      %PlannerEntry{}
      |> Library.change_planner_entry(planner_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
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
