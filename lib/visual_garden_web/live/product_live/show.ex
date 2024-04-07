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
  def handle_params(%{"garden_id" => garden_id, "id" => id}, action, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:product, Gardens.get_product!(id))
     |> assign(:garden, Gardens.get_garden!(garden_id))}
  end

  @impl true
  def handle_info({VisualGardenWeb.EventLogLive.FormComponent, {:saved, event_log}}, socket) do
    {:noreply, stream_insert(socket, :events, event_log)}
  end

  defp page_title(:show), do: "Show product"
  defp page_title(:edit), do: "Edit product"
  defp page_title(:new_water), do: "New Event"
end
