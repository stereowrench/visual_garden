defmodule VisualGardenWeb.PlantLive.Index do
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
     |> stream(:nursery, Gardens.get_nursery_entries_not_planted(garden.id))
     |> stream(:plants, unarchived_plants)
     |> stream(:archived_plants, archived_plants)}
  end

  def mount(%{"garden_id" => garden_id}, _session, socket) do
    garden = Gardens.get_garden!(garden_id)

    Authorization.authorize_garden_view(garden.id, socket.assigns.current_user)

    plants = Gardens.list_plants(garden_id)
    unarchived_plants = plants |> Enum.filter(&(!&1.archived))
    archived_plants = plants |> Enum.filter(& &1.archived)

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
     |> stream(:nursery, Gardens.get_nursery_entries_not_planted(garden.id))
     |> stream(:plants, unarchived_plants)
     |> stream(:archived_plants, archived_plants)}
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

  @impl true
  def handle_info({VisualGardenWeb.PlantLive.FormComponent, {:saved, plant}}, socket) do
    plant = VisualGarden.Repo.preload(plant, [:seed, :product])
    {:noreply, stream_insert(socket, :plants, plant)}
  end

  @impl true
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
end
