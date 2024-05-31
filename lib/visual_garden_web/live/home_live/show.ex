defmodule VisualGardenWeb.HomeLive.Show do
  alias VisualGardenWeb.Tooltips
  alias VisualGarden.MyDateTime
  alias VisualGarden.Gardens
  alias VisualGarden.Repo
  alias VisualGarden.Planner
  use VisualGardenWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"nursery_entry" => neid}, _, socket) do
    {:noreply,
     socket
     |> assign_assigns()
     |> assign(:entry, Gardens.get_nursery_entry!(neid))
     |> assign(:page_title, page_title(socket.assigns.live_action))}
  end

  @impl true
  def handle_params(_params, _, socket) do
    {:noreply,
     socket
     |> assign_assigns()
     |> assign(:page_tip, Tooltips.home_content())
     |> assign(:page_tip_title, Tooltips.home_title())
     |> assign(:page_title, page_title(socket.assigns.live_action))}
  end

  defp assign_assigns(socket) do
    todo_items =
      Planner.get_todo_items(socket.assigns.current_user)
      |> Enum.sort_by(& &1.date, Date)

    planner_entries =
      Planner.list_planner_entries_for_user(socket.assigns.current_user)
      |> Enum.group_by(& &1.id)
      |> Enum.map(fn {a, [b]} -> {a, b} end)
      |> Enum.into(%{})

    socket
    |> assign(:todo_items, todo_items)
    |> assign(:gardens, Gardens.list_gardens(socket.assigns.current_user))
    |> assign(:planner_entries, planner_entries)
  end

  def render_todo_item(assigns) do
    case assigns.item.type do
      "nursery_plant" -> render_nursery_plant(assigns)
      "nursery_overdue" -> render_nursery_overdue(assigns)
      "plant" -> render_plant(assigns)
      "plant_overdue" -> render_plant_overdue(assigns)
      "orphaned_nursery" -> render_orphaned_nursery(assigns)
    end
  end

  def render_orphaned_nursery(assigns) do
    ~H"""
    <div>
      Orphaned Seedling <%= @item.name %>
      <.link patch={~p"/home/orphaned_nursery/#{@item.nursery_entry_id}"} class="orphan-link">
        <.button>
          Plant orphan
        </.button>
      </.link>
    </div>
    """
  end

  def render_nursery_plant(assigns) do
    assigns =
      assign(assigns, remaining_days: Timex.diff(assigns.item.end_date, assigns.item.date, :days))
      |> assign(entry: assigns.planner_entries[assigns.item.planner_entry_id])

    # IO.inspect(assigns.planner_entries[assigns.item.planner_entry_id])

    ~H"""
    <div>
      (<%= Timex.format(@item.date, "{relative}", :relative) |> elem(1) %>)
      Nurse <%= @entry.seed.name %> (<%= @remaining_days %> days left) in <%= @entry.bed.name %> (<%= @entry.row %>, <%= @entry.column %>)
      <%= unless Timex.after?(@item.date, MyDateTime.utc_today) do %>
        <.button
          phx-click={JS.push("nurse", value: %{planner_entry_id: @entry.id})}
          data-confirm="Are you sure?"
        >
          Nurse
        </.button>
      <% end %>
    </div>
    """
  end

  def render_nursery_overdue(assigns) do
    assigns =
      assigns
      |> assign(entry: assigns.planner_entries[assigns.item.planner_entry_id])

    ~H"""
    <div>
      (<%= Timex.format(@item.date, "{relative}", :relative) |> elem(1) %>)
      Overdue Nursery <%= @entry.seed.name %> in <%= @entry.bed.name %> (<%= @entry.row %>, <%= @entry.column %>)
      <%= unless Timex.after?(@item.date, MyDateTime.utc_today) do %>
        <.button
          phx-click={JS.push("delete_planner", value: %{planner_entry_id: @entry.id})}
          data-confirm="Are you sure?"
        >
          Delete Planner Entry
        </.button>
      <% end %>
    </div>
    """
  end

  def render_plant(assigns) do
    assigns =
      assign(assigns, remaining_days: Timex.diff(assigns.item.end_date, assigns.item.date, :days))
      |> assign(entry: assigns.planner_entries[assigns.item.planner_entry_id])

    # IO.inspect(assigns.planner_entries[assigns.item.planner_entry_id])
    ~H"""
    <div>
      (<%= Timex.format(@item.date, "{relative}", :relative) |> elem(1) %>)
      Plant <%= @entry.seed.name %> (<%= @remaining_days %> days left) in <%= @entry.bed.name %> (<%= @entry.row %>, <%= @entry.column %>)
      <%= unless Timex.after?(@item.date, MyDateTime.utc_today) do %>
        <.button
          phx-click={JS.push("plant", value: %{planner_entry_id: @entry.id})}
          data-confirm="Are you sure?"
        >
          Plant
        </.button>
      <% end %>
    </div>
    """
  end

  def render_plant_overdue(assigns) do
    assigns =
      assigns
      |> assign(entry: assigns.planner_entries[assigns.item.planner_entry_id])

    ~H"""
    <div>
      (<%= Timex.format(@item.date, "{relative}", :relative) |> elem(1) %>)
      Overdue Plant <%= @entry.seed.name %> in <%= @entry.bed.name %> (<%= @entry.row %>, <%= @entry.column %>)
      <%= unless Timex.after?(@item.date, MyDateTime.utc_today) do %>
        <.button
          phx-click={JS.push("delete_planner", value: %{planner_entry_id: @entry.id})}
          data-confirm="Are you sure?"
        >
          Delete Planner Entry
          <%= if @entry.nursery_entry do %>
            (Has nursery entry)
          <% end %>
        </.button>
      <% end %>
    </div>
    """
  end

  def handle_event("delete_planner", %{"planner_entry_id" => peid}, socket) do
    Repo.transaction(fn ->
      entry = Planner.get_planner_entry!(peid)
      garden = Gardens.get_garden!(entry.bed.garden_id)
      Authorization.authorize_garden_modify(garden.id, socket.assigns.current_user)

      if entry.nursery_entry do
        Gardens.update_nursery_entry(entry.nursery_entry, %{planner_entry_id: nil})
      end

      Planner.delete_planner_entry(entry)
    end)

    {:noreply, assign_assigns(socket)}
  end

  def handle_event("plant", %{"planner_entry_id" => peid}, socket) do
    Repo.transaction(fn ->
      entry = Planner.get_planner_entry!(peid)
      garden = Gardens.get_garden!(entry.bed.garden_id)
      Authorization.authorize_garden_modify(garden.id, socket.assigns.current_user)

      {:ok, plant} =
        Gardens.create_plant(%{
          name: "#{entry.seed.name} - #{entry.seed.type}",
          qty: 1,
          row: entry.row,
          column: entry.column,
          seed_id: entry.seed_id,
          product_id: entry.bed_id
        })

      {:ok, _} = Planner.set_planner_entry_plant(entry, plant.id, garden)
    end)

    {:noreply, assign_assigns(socket)}
  end

  @impl true
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
  defp page_title(:new_garden), do: "New Garden"
  defp page_title(:orphaned_nursery), do: "Plant Orphaned Nursery"

  @impl true
  def handle_info({VisualGardenWeb.GardenLive.FormComponent, {:saved, garden}}, socket) do
    {:noreply, socket |> assign(:gardens, Gardens.list_garden_users(socket.assigns.current_user))}
  end

  @impl true
  def handle_info({VisualGardenWeb.HomeLive.TemplatePlantComponent, :refresh}, socket) do
    {:noreply, assign_assigns(socket)}
  end
end
