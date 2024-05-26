defmodule VisualGardenWeb.HomeLive.Show do
  alias VisualGarden.MyDateTime
  alias VisualGarden.Gardens
  alias VisualGarden.Repo
  alias VisualGarden.Gardens.Plant
  alias VisualGarden.Planner
  use VisualGardenWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _, socket) do
    {:noreply,
     socket
     |> assign_assigns()
     |> assign(:page_tip, "Lorme ipsum")
     |> assign(:page_tip_title, "Using the task list")
     |> assign(:page_title, page_title(socket.assigns.live_action))}
  end

  defp assign_assigns(socket) do
    todo_items = Planner.get_todo_items(socket.assigns.current_user)

    planner_entries =
      Planner.list_planner_entries_for_user(socket.assigns.current_user)
      |> Enum.group_by(& &1.id)
      |> Enum.map(fn {a, [b]} -> {a, b} end)
      |> Enum.into(%{})

    socket
    |> assign(:todo_items, todo_items)
    |> assign(:planner_entries, planner_entries)
  end

  def render_todo_item(assigns) do
    case assigns.item.type do
      "nursery_plant" -> render_nursery_plant(assigns)
      "nursery_overdue" -> render_nursery_overdue(assigns)
      "plant" -> render_plant(assigns)
      "plant_overdue" -> render_plant_overdue(assigns)
    end
  end

  def render_nursery_plant(assigns) do
    assigns =
      assign(assigns, remaining_days: Timex.diff(assigns.item.end_date, assigns.item.date, :days))
      |> assign(entry: assigns.planner_entries[assigns.item.planner_entry_id])

    # IO.inspect(assigns.planner_entries[assigns.item.planner_entry_id])

    ~H"""
    <div>
      Nurse <%= @entry.seed.name %> (<%= @remaining_days %> days left) in <%= @entry.bed.name %> (<%= @entry.row %>, <%= @entry.column %>)
      <.button
        phx-click={JS.push("nurse", value: %{planner_entry_id: @entry.id})}
        data-confirm="Are you sure?"
      >
        Nurse
      </.button>
    </div>
    """
  end

  def render_nursery_overdue(assigns) do
    ~H"""

    """
  end

  def render_plant(assigns) do
    ~H"""

    """
  end

  def render_plant_overdue(assigns) do
    ~H"""

    """
  end

  # def handle_event("plant", %{"planner_entry_id" => peid}, socket) do
  #   Repo.transaction(fn ->
  #     entry = Planner.get_planner_entry!(peid)
  #     garden = Gardens.get_garden!(entry.garden_id)
  #     Authorization.authorize_garden_modify(garden.id, socket.assigns.current_user)

  #     {:ok, plant} = Gardens.create_plant(%{
  #       name: "#{entry.seed.name} - #{entry.seed.type}",
  #       qty: 1,
  #     })

  #     {:ok, _} = Planner.set_planner_entry_plant(entry, plant.id, socket.assigns.garden)
  #   end)

  #   {:noreply, assign_assigns(socket)}
  # end

  def handle_event("nurse", %{"planner_entry_id" => peid}, socket) do
    Repo.transaction(fn ->
      entry = Planner.get_planner_entry!(peid)
      garden = Gardens.get_garden!(entry.bed.garden_id)
      Authorization.authorize_garden_modify(garden.id, socket.assigns.current_user)

      {:ok, _} =
        Gardens.create_nursery_entry(%{
          sow_date: MyDateTime.utc_today(),
          planner_entry_id: entry.id,
          seed_id: entry.seed.id,
          garden_id: garden.id
        })

      Planner.set_entry_nurse_date(entry, garden)
    end)

    {:noreply, assign_assigns(socket)}
  end

  defp page_title(:show), do: "Show Nursery entry"
end
