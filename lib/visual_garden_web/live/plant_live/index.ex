defmodule VisualGardenWeb.PlantLive.Index do
  use VisualGardenWeb, :live_view

  alias VisualGarden.Gardens
  alias VisualGarden.Gardens.Plant

  @impl true
  def mount(%{"garden_id" => garden_id, "product_id" => product_id}, _session, socket) do
    {:ok, stream(socket, :plants, Gardens.list_plants(garden_id, product_id))}
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
    {:noreply, stream_insert(socket, :plants, plant)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    plant = Gardens.get_plant!(id)
    {:ok, _} = Gardens.delete_plant(plant)

    {:noreply, stream_delete(socket, :plants, plant)}
  end
end
