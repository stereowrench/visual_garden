defmodule VisualGardenWeb.PlantLive.Show do
  use VisualGardenWeb, :live_view

  alias VisualGarden.Gardens

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(
        %{"garden_id" => garden_id, "product_id" => product_id, "id" => id},
        _,
        socket
      ) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:garden, Gardens.get_garden!(garden_id))
     |> assign(:product, Gardens.get_product!(product_id))
     |> assign(:plant, Gardens.get_plant!(id))
     |> stream(:events, Gardens.list_event_logs(product_id, id))}
  end

  defp page_title(:show), do: "Show Plant"
  defp page_title(:edit), do: "Edit Plant"

  @impl true
  def handle_info({VisualGardenWeb.PlantLive.FormComponent, {:saved, plant}}, socket) do
    {:noreply,
     socket
     |> assign(:plant, plant)
     |> stream(:events, Gardens.list_event_logs(plant.product_id, plant.id))}
  end
end
