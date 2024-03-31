defmodule VisualGardenWeb.HarvestLive.Index do
  use VisualGardenWeb, :live_view

  alias VisualGarden.Gardens
  alias VisualGarden.Gardens.Harvest

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :harvests, Gardens.list_harvests())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Harvest")
    |> assign(:harvest, Gardens.get_harvest!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Harvest")
    |> assign(:harvest, %Harvest{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Harvests")
    |> assign(:harvest, nil)
  end

  @impl true
  def handle_info({VisualGardenWeb.HarvestLive.FormComponent, {:saved, harvest}}, socket) do
    {:noreply, stream_insert(socket, :harvests, harvest)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    harvest = Gardens.get_harvest!(id)
    {:ok, _} = Gardens.delete_harvest(harvest)

    {:noreply, stream_delete(socket, :harvests, harvest)}
  end
end
