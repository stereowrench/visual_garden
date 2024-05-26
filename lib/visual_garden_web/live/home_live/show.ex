defmodule VisualGardenWeb.HomeLive.Show do
  alias VisualGarden.Gardens.Plant
  alias VisualGarden.Planner
  use VisualGardenWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _, socket) do
    todo_items = Planner.get_todo_items(socket.assigns.current_user)

    planner_entries =
      Planner.list_planner_entries_for_user(socket.assigns.current_user)
      |> Enum.group_by(& &1.id)
      |> Enum.map(fn {a, [b]} -> {a, b} end)
      |> Enum.into(%{})

    {:noreply,
     socket
     |> assign(:todo_items, todo_items)
     |> assign(:planner_entries, planner_entries)
     |> assign(:page_tip, "Lorme ipsum")
     |> assign(:page_tip_title, "Using the task list")
     |> assign(:page_title, page_title(socket.assigns.live_action))}
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
      Plant <%= @entry.seed.name %> (<%= @remaining_days %> days left) in <%= @entry.bed.name %> (<%= @entry.row %>, <%= @entry.column %>)
      <.link patch={~p"/home/#{@item.planner_entry_id}/plant"}>
        <.button>
          Plant
        </.button>
      </.link>
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

  defp page_title(:show), do: "Show Nursery entry"
end
