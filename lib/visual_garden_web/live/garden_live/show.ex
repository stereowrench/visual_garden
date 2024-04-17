defmodule VisualGardenWeb.GardenLive.Show do
  use VisualGardenWeb, :live_view

  alias VisualGarden.Gardens

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:garden, Gardens.get_garden!(id))
     |> assign(:seeds, Gardens.list_seeds(id))
     |> assign(:plants, Gardens.list_plants(id))
     |> assign(:products, Gardens.list_products(id))}
  end

  defp page_title(:show), do: "Show Garden"
  defp page_title(:edit), do: "Edit Garden"
  defp page_title(:plant), do: "Plant"

  @impl true
  def handle_info({VisualGardenWeb.GardenLive.FormComponent, {:saved, garden}}, socket) do
    {:noreply, assign(socket, :garden, garden)}
  end
  def handle_info({VisualGardenWeb.PlantLive.FormComponent, {:saved, _plant}}, socket) do
    {:noreply, assign(socket, :plants, Gardens.list_plants(socket.assigns.garden.id))}
  end
end
