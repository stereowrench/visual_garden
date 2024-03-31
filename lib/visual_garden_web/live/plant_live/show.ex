defmodule VisualGardenWeb.PlantLive.Show do
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
     |> assign(:plant, Gardens.get_plant!(id))}
  end

  defp page_title(:show), do: "Show Plant"
  defp page_title(:edit), do: "Edit Plant"
end
