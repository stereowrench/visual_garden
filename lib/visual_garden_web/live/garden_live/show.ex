defmodule VisualGardenWeb.GardenLive.Show do
  alias VisualGarden.Planner
  alias VisualGarden.Accounts
  use VisualGardenWeb, :live_view

  alias VisualGarden.Gardens

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    Authorization.authorize_garden_view(id, socket.assigns.current_user)
    garden = Gardens.get_garden!(id)
    products = Gardens.list_products(id)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:planned_entries, get_planned_entries(garden))
     |> assign(:total_sqft, total_sqft(products))
     |> assign(:archived_plants, archived_plants(garden))
     |> assign(:garden, garden)
     |> assign(:seeds, Gardens.list_seeds(id))
     |> assign(
       :can_modify?,
       Authorization.can_modify_garden?(garden, socket.assigns.current_user)
     )
     |> assign_plants()
     |> assign(:users, Gardens.list_garden_users(garden))
     |> assign(:products, products)}
  end

  defp archived_plants(garden) do
    beds = Gardens.list_beds(garden.id)

    for bed <- beds do
      Gardens.list_plants(garden.id, bed.id)
      |> Enum.filter(& &1.archived)
      |> length()
    end
    |> Enum.sum()
  end

  defp get_planned_entries(garden) do
    Planner.list_planner_entries_ungrouped(garden.id)
    |> length()
  end

  defp total_sqft(products) do
    products
    |> Enum.filter(&(&1.type == :bed))
    |> Enum.map(fn b -> b.width * b.length end)
    |> Enum.sum()
  end

  defp page_title(:show), do: "Show Garden"
  defp page_title(:edit), do: "Edit Garden"
  defp page_title(:collab), do: "Add Collaborators"

  @impl true
  def handle_info({VisualGardenWeb.GardenLive.FormComponent, {:saved, garden}}, socket) do
    {:noreply, assign(socket, :garden, garden)}
  end

  def handle_info({VisualGardenWeb.PlantLive.FormComponent, {:saved, _plant}}, socket) do
    {:noreply, assign_plants(socket)}
  end

  def handle_info({VisualGardenWeb.GardenLive.CollabComponent, {:saved, _}}, socket) do
    {:noreply,
     socket
     |> assign(:users, Gardens.list_garden_users(socket.assigns.garden))}
  end

  defp assign_plants(socket) do
    plants = Gardens.list_plants(socket.assigns.garden.id)

    total_plants =
      plants
      |> Enum.map(& &1.qty)
      |> Enum.sum()

    socket
    |> assign(:plants, plants)
    |> assign(:total_plants, total_plants)
  end

  @impl true
  def handle_event("delete", %{"id" => user_id}, socket) do
    Authorization.authorize_garden_modify(socket.assigns.garden.id, socket.assigns.current_user)
    user = Accounts.get_user!(user_id)

    if gu = Gardens.get_garden_user(socket.assigns.garden, user) do
      Gardens.delete_garden_user(gu)
    end

    {:noreply,
     socket
     |> assign(:users, Gardens.list_garden_users(socket.assigns.garden))}
  end
end
