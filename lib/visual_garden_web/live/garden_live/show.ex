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
     |> assign_plants()
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
    {:noreply, assign_plants(socket)}
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

end
