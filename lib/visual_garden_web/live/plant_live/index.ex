defmodule VisualGardenWeb.PlantLive.Index do
  alias VisualGardenWeb.HomeBadge
  alias VisualGarden.Repo
  alias VisualGarden.MyDateTime
  alias VisualGarden.Planner
  alias VisualGarden.Authorization.UnauthorizedError
  use VisualGardenWeb, :live_view

  alias VisualGarden.Gardens
  alias VisualGarden.Gardens.Plant

  @impl true
  def mount(%{"garden_id" => garden_id, "product_id" => product_id}, _session, socket) do
    garden = Gardens.get_garden!(garden_id)
    Authorization.authorize_garden_view(garden.id, socket.assigns.current_user)
    plants = Gardens.list_plants(garden_id, product_id)
    unarchived_plants = plants |> Enum.filter(&(!&1.archived))
    archived_plants = plants |> Enum.filter(& &1.archived)

    {:ok,
     socket
     |> assign(
       :can_modify?,
       Authorization.can_modify_garden?(garden, socket.assigns.current_user)
     )
     |> assign(:product, Gardens.get_product!(product_id))
     |> assign(:seeds, Gardens.list_seeds(garden_id))
     |> assign(:beds, Gardens.list_beds(garden_id))
     |> assign(:garden, garden)
     |> assign_plants()
     |> assign_todos()}
  end

  def mount(%{"garden_id" => garden_id}, _session, socket) do
    garden = Gardens.get_garden!(garden_id)

    Authorization.authorize_garden_view(garden.id, socket.assigns.current_user)

    {:ok,
     socket
     |> assign(
       :can_modify?,
       Authorization.can_modify_garden?(garden, socket.assigns.current_user)
     )
     |> assign(:product, nil)
     |> assign(:garden, garden)
     |> assign(:seeds, Gardens.list_seeds(garden_id))
     |> assign(:beds, Gardens.list_beds(garden_id))
     |> assign_plants()
     |> assign_todos()}
  end

  defp assign_plants(socket) do
    garden = socket.assigns.garden
    garden_id = socket.assigns.garden.id
    plants = Gardens.list_plants(garden_id)
    unarchived_plants = plants |> Enum.filter(&(!&1.archived))
    archived_plants = plants |> Enum.filter(& &1.archived)

    socket
    |> stream(:nursery, Gardens.get_nursery_entries_not_planted(garden.id))
    |> stream(:plants, unarchived_plants)
    |> stream(:archived_plants, archived_plants)
  end

  def assign_todos(socket) do
    todos =
      Planner.get_todo_items(socket.assigns.current_user)
      |> Enum.filter(&(Timex.compare(MyDateTime.utc_today(), &1.date) >= 0))
      |> Enum.filter(
        &(&1.type in [
            "plant",
            "plant_overdue",
            "nursery_plant",
            "nursery_overdue",
            "orphaned_nursery",
            "refuse"
          ] && &1.garden_id == socket.assigns.garden.id)
      )

    planner_entries =
      Planner.list_planner_entries_for_user(socket.assigns.current_user)
      |> Enum.group_by(& &1.id)
      |> Enum.map(fn {a, [b]} -> {a, b} end)
      |> Enum.into(%{})

    socket
    |> assign(:todo_items, todos)
    |> assign(:planner_entries, planner_entries)
    |> HomeBadge.badge_socket()
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Plant")
    |> assign(:plant, Gardens.get_plant!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Plant")
    |> assign(:plant, %Plant{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Plants")
    |> assign(:plant, nil)
  end

  defp apply_action(socket, :orphaned_nursery, %{"nursery_entry" => neid}) do
    ne = Gardens.get_nursery_entry!(neid)

    if ne.garden_id != socket.assigns.garden.id do
      raise UnauthorizedError
    end

    socket
    |> assign(:page_title, "Orphaned Nursery Entry")
    |> assign(:entry, ne)
  end

  @impl true
  def handle_info({VisualGardenWeb.PlantLive.FormComponent, {:saved, plant}}, socket) do
    plant = VisualGarden.Repo.preload(plant, [:seed, :product])
    {:noreply, stream_insert(socket, :plants, plant)}
  end

  @impl true
  def render_todo_item(assigns) do
    case assigns.item.type do
      "nursery_plant" -> render_nursery_plant(assigns)
      "nursery_overdue" -> render_nursery_overdue(assigns)
      "plant" -> render_plant(assigns)
      "plant_overdue" -> render_plant_overdue(assigns)
      "orphaned_nursery" -> render_orphaned_nursery(assigns)
      "refuse" -> render_refuse(assigns)
    end
  end

  def render_orphaned_nursery(assigns) do
    ~H"""
    <div>
      <div class="border-b border-gray-200 bg-white px-4 py-5 sm:px-6">
        <h3 class="text-base font-semibold leading-6 text-gray-900">
          Orphaned Seedling <%= @item.name %>
        </h3>
      </div>
      <.link
        navigate={~p"/gardens/#{@garden.id}/plants/orphaned_nursery/#{@item.nursery_entry_id}"}
        class="orphan-link"
      >
        <.button>
          Plant orphan
        </.button>
      </.link>
    </div>
    """
  end

  def render_refuse(assigns) do
    ~H"""
    <div class="mt-6 border-t border-gray-100">
      <div class="divide-y divide-gray-200 overflow-hidden rounded-lg bg-white shadow">
        <div class="border-b border-gray-200 bg-white px-4 py-5 sm:px-6">
          <h3 class="text-base font-semibold leading-6 text-gray-900">
            🗑️ Refuse Plant <%= @item.plant.name %> in <%= @item.bed.name %>
          </h3>
        </div>
        <dl>
          <div class="dldiv">
            <dt>Refuse date</dt>
            <dd>
              <%= @item.date %>
            </dd>
          </div>
        </dl>
        <%!-- <%= unless Timex.after?(@item.date, MyDateTime.utc_today) do %> --%>
        <%= unless false do %>
          <.button
            phx-click={
              JS.push("refuse", value: %{pe_id: @item.planner_entry_id, garden_id: @item.garden_id})
            }
            data-confirm="Are you sure?"
          >
            Refuse
          </.button>
        <% end %>
      </div>
    </div>
    """
  end

  def render_nursery_plant(assigns) do
    assigns =
      assign(assigns, remaining_days: Timex.diff(assigns.item.end_date, assigns.item.date, :days))
      |> assign(entry: assigns.planner_entries[assigns.item.planner_entry_id])

    # IO.inspect(assigns.planner_entries[assigns.item.planner_entry_id])

    ~H"""
    <div class="mt-6 border-t border-gray-100">
      <div class="divide-y divide-gray-200 overflow-hidden rounded-lg bg-white shadow">
        <div class="border-b border-gray-200 bg-white px-4 py-5 sm:px-6">
          <h3 class="text-base font-semibold leading-6 text-gray-900">
            🌱 Nurse "<%= @entry.seed.name %>" in <%= @entry.bed.name %>
          </h3>
        </div>
        <dl>
          <div class="dldiv">
            <dt>In Season</dt>
            <dd>
              <%= Timex.format(@item.date, "{relative}", :relative) |> elem(1) %> (<%= @remaining_days %> days left)
            </dd>
          </div>
          <div class="dldiv">
            <dt>What</dt>
            <dd><%= @entry.seed.name %></dd>
          </div>
        </dl>
        <%= unless Timex.after?(@item.date, MyDateTime.utc_today) do %>
          <.button
            phx-click={JS.push("nurse", value: %{planner_entry_id: @entry.id})}
            data-confirm="Are you sure?"
          >
            Nurse
          </.button>
        <% end %>
      </div>
    </div>
    """
  end

  def render_nursery_overdue(assigns) do
    assigns =
      assigns
      |> assign(entry: assigns.planner_entries[assigns.item.planner_entry_id])

    ~H"""
    <div>
      <div class="mt-6 border-t border-gray-100">
        <div class="divide-y divide-gray-200 overflow-hidden rounded-lg bg-white shadow">
          <div class="border-b border-gray-200 bg-white px-4 py-5 sm:px-6">
            <h3 class="text-base font-semibold leading-6 text-gray-900">
              Overdue Nursery <%= @entry.seed.name %> in <%= @entry.bed.name %> (<%= @entry.row %>, <%= @entry.column %>)
            </h3>
            <dl>
              <div class="dldiv">
                <dt>What?</dt>
                <dd>
                  This plant was not planted in time for the schedule it is assigned to. Delete the planner entry and create a new one to proceed.
                </dd>
              </div>
              <div class="dldiv">
                <dt>When?</dt>
                <dd>
                  <%= Timex.format(@item.date, "{relative}", :relative) |> elem(1) %>
                </dd>
              </div>
            </dl>
            <%= unless Timex.after?(@item.date, MyDateTime.utc_today) do %>
              <.button
                phx-click={JS.push("delete_planner", value: %{planner_entry_id: @entry.id})}
                data-confirm="Are you sure?"
              >
                Delete Planner Entry
              </.button>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def render_plant(assigns) do
    assigns =
      assign(assigns, remaining_days: Timex.diff(assigns.item.end_date, assigns.item.date, :days))
      |> assign(entry: assigns.planner_entries[assigns.item.planner_entry_id])

    ~H"""
    <div class="mt-6 border-t border-gray-100">
      <div class="divide-y divide-gray-200 overflow-hidden rounded-lg bg-white shadow">
        <div class="border-b border-gray-200 bg-white px-4 py-5 sm:px-6">
          <h3 class="text-base font-semibold leading-6 text-gray-900">
            🪴 Plant <%= @entry.common_name %> in <%= @garden.name %>
          </h3>
        </div>
        <dl>
          <div class="dldiv">
            <dt>In Season</dt>
            <dd>
              <%= Timex.format(@item.date, "{relative}", :relative) |> elem(1) %> (<%= @remaining_days %> days left)
            </dd>
          </div>
          <div class="dldiv">
            <dt>What</dt>
            <dd><%= @entry.seed.name %></dd>
          </div>
          <div class="dldiv">
            <dt>Where</dt>
            <dd>(<%= @entry.row %>, <%= @entry.column %>) in <%= @entry.bed.name %></dd>
          </div>
        </dl>
        <%= unless Timex.after?(@item.date, MyDateTime.utc_today) do %>
          <.button
            phx-click={JS.push("plant", value: %{planner_entry_id: @entry.id})}
            disabled={@item.disabled}
            data-confirm="Are you sure?"
          >
            Plant
          </.button>
        <% end %>
      </div>
    </div>
    """
  end

  def render_plant_overdue(assigns) do
    assigns =
      assigns
      |> assign(entry: assigns.planner_entries[assigns.item.planner_entry_id])

    ~H"""
    <div>
      <div class="mt-6 border-t border-gray-100">
        <div class="divide-y divide-gray-200 overflow-hidden rounded-lg bg-white shadow">
          <div class="border-b border-gray-200 bg-white px-4 py-5 sm:px-6">
            <h3 class="text-base font-semibold leading-6 text-gray-900">
              Overdue Plant <%= @entry.seed.name %> in <%= @entry.bed.name %> (<%= @entry.row %>, <%= @entry.column %>)
            </h3>
          </div>
          <dl>
            <div class="dldiv">
              <dt>What?</dt>
              <dd>
                This plant was not planted in time for the schedule it is assigned to. Delete the planner entry and create a new one to proceed.
              </dd>
            </div>
            <div class="dldiv">
              <dt>When?</dt>
              <dd>
                <%= Timex.format(@item.date, "{relative}", :relative) |> elem(1) %>
              </dd>
            </div>
          </dl>
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
      </div>
    </div>
    """
  end

  def handle_event("delete", %{"id" => id}, socket) do
    Authorization.authorize_garden_modify(socket.assigns.garden.id, socket.assigns.current_user)
    plant = Gardens.get_plant!(id)

    gid = Gardens.get_product!(plant.product_id).garden_id

    unless gid == socket.assigns.garden.id do
      raise UnauthorizedError
    end

    {:ok, _} = Gardens.delete_plant(plant)

    {:noreply, stream_delete(socket, :plants, plant)}
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

    {:noreply, assign_todos(socket)}
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

    {:noreply, assign_todos(socket)}
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

    {:noreply, assign_todos(socket)}
  end

  @impl true
  def handle_event("refuse", %{"pe_id" => peid}, socket) do
    pe = Planner.get_planner_entry!(peid)
    bed = Gardens.get_product!(pe.bed_id)
    garden = Gardens.get_garden!(bed.garden_id)
    Authorization.authorize_garden_modify(garden.id, socket.assigns.current_user)
    plant = Gardens.get_plant!(pe.plant_id)
    {:ok, _} = Gardens.archive_plant(plant)

    {:noreply, assign_todos(socket)}
  end
end
