defmodule VisualGardenWeb.EventLogLive.Show do
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
     |> assign(:event_log, Gardens.get_event_log!(id))}
  end

  defp page_title(:show), do: "Show Event log"
  defp page_title(:edit), do: "Edit Event log"
end
