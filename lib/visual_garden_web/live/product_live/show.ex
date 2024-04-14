defmodule VisualGardenWeb.ProductLive.Show do
  use VisualGardenWeb, :live_view

  alias VisualGarden.Gardens

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    els = Gardens.list_event_logs(id)
    socket = stream(socket, :events, els)
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"garden_id" => garden_id, "id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:product, Gardens.get_product!(id))
     |> assign(:products, Gardens.list_products(garden_id))
     |> assign(:garden, Gardens.get_garden!(garden_id))}
  end

  @impl true
  def handle_info({VisualGardenWeb.EventLogLive.FormComponent, {:saved, event_log}}, socket) do
    {:noreply, stream_insert(socket, :events, event_log)}
  end

  def handle_info({VisualGardenWeb.ProductLive.FormComponent, {:saved, product}}, socket) do
    {:noreply, assign(socket, :product, product)}
  end

  defp page_title(:show), do: "Show product"
  defp page_title(:edit), do: "Edit product"
  defp page_title(:new_water), do: "Watering"
  defp page_title(:till), do: "Tilling"
  defp page_title(:transfer), do: "Transferring"
end
