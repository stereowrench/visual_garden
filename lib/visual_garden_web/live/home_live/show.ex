defmodule VisualGardenWeb.HomeLive.Show do
  alias VisualGarden.Authorization.UnauthorizedError
  alias Hex.API.Auth
  alias VisualGardenWeb.DisplayHelpers
  alias VisualGarden.Library
  alias VisualGardenWeb.Tooltips
  alias VisualGarden.MyDateTime
  alias VisualGarden.Gardens
  alias VisualGarden.Repo
  alias VisualGarden.Planner
  use VisualGardenWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if socket.assigns.current_user do
      {:ok, socket}
    else
      {:ok, socket |> redirect(to: ~p"/")}
    end
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
  def handle_params(%{"garden_id" => neid, "bed_id" => bid}, _, socket) do
    bed = Gardens.get_product!(bid)
    garden = Gardens.get_garden!(neid)

    if bed.garden_id != garden.id do
      raise UnauthorizedError
    end

    Authorization.authorize_garden_modify(garden.id, socket.assigns.current_user)

    {:noreply,
     socket
     |> assign_assigns()
     |> assign(:garden, garden)
     |> assign(
       :products,
       Gardens.list_products(garden.id) |> Enum.filter(&(&1.type == :growing_media))
     )
     |> assign(:bed, bed)
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

    species_in_order =
      for garden <- Gardens.list_gardens(socket.assigns.current_user) |> Repo.preload([:region]),
          into: %{} do
        soon_list = Library.list_species_in_order(garden.region_id)
        {garden, soon_list}
      end

    socket
    |> assign(:todo_items, todo_items)
    |> assign(:species_in_order, species_in_order)
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
      "water" -> render_water(assigns)
      "media" -> render_media(assigns)
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
      <.link patch={~p"/home/orphaned_nursery/#{@item.nursery_entry_id}"} class="orphan-link">
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

  def render_media(assigns) do
    ~H"""
    <div class="mt-6 border-t border-gray-100">
      <div class="divide-y divide-gray-200 overflow-hidden rounded-lg bg-white shadow">
        <div class="border-b border-gray-200 bg-white px-4 py-5 sm:px-6">
          <h3 class="text-base font-semibold leading-6 text-gray-900">
            🌎 Fill bed with media <%= @item.bed.name %>
          </h3>
        </div>
        <%= unless Timex.after?(@item.date, MyDateTime.utc_today) do %>
          <.link navigate={~p"/home/#{@item.garden_id}/#{@item.bed.id}/transfer"}>
            <.button>
              Add media
            </.button>
          </.link>
        <% end %>
      </div>
    </div>
    """
  end

  def render_water(assigns) do
    ~H"""
    <div class="mt-6 border-t border-gray-100">
      <div class="divide-y divide-gray-200 overflow-hidden rounded-lg bg-white shadow">
        <div class="border-b border-gray-200 bg-white px-4 py-5 sm:px-6">
          <h3 class="text-base font-semibold leading-6 text-gray-900">
            💦 Water <%= @item.bed.name %>
          </h3>
        </div>
        <dl>
          <div class="dldiv">
            <dt>Last Watered</dt>
            <dd>
              <%= if @item.last_water do
                Timex.format(@item.last_water, "{relative}", :relative) |> elem(1)
              else
                "never"
              end %>
            </dd>
          </div>
        </dl>
        <%= unless Timex.after?(@item.date, MyDateTime.utc_today) do %>
          <.button
            phx-click={JS.push("water", value: %{bed_id: @item.bed.id})}
            data-confirm="Are you sure?"
          >
            Water
          </.button>
          <.button
            phx-click={JS.push("humidity", value: %{bed_id: @item.bed.id})}
            data-confirm="Are you sure?"
          >
            Already moist
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


  @impl true
  def handle_event("refuse", %{"pe_id" => peid}, socket) do
    pe = Planner.get_planner_entry!(peid)
    bed = Gardens.get_product!(pe.bed_id)
    garden = Gardens.get_garden!(bed.garden_id)
    Authorization.authorize_garden_modify(garden.id, socket.assigns.current_user)
    plant = Gardens.get_plant!(pe.plant_id)
    {:ok, _} = Gardens.archive_plant(plant)

    {:noreply, assign_assigns(socket)}
  end

  defp page_title(:show), do: "Show Nursery entry"
  defp page_title(:new_garden), do: "New Garden"
  defp page_title(:orphaned_nursery), do: "Plant Orphaned Nursery"
  defp page_title(:transfer), do: "Fill bed"

  @impl true
  def handle_info({VisualGardenWeb.GardenLive.FormComponent, {:saved, garden}}, socket) do
    {:noreply, socket |> assign(:gardens, Gardens.list_garden_users(socket.assigns.current_user))}
  end

  @impl true
  def handle_info({VisualGardenWeb.HomeLive.TemplatePlantComponent, :refresh}, socket) do
    {:noreply, assign_assigns(socket)}
  end

  @impl true
  def handle_info({VisualGardenWeb.EventLogLive.FormComponent, {:saved, _event_log}}, socket) do
    {:noreply, assign_assigns(socket)}
  end
end
