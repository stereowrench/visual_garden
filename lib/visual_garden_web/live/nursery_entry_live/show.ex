defmodule VisualGardenWeb.NurseryEntryLive.Show do
  use VisualGardenWeb, :live_view

  alias VisualGarden.Gardens

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id, "garden_id" => garden_id}, _, socket) do
    garden = Gardens.get_garden!(garden_id)

    {:noreply,
     socket
     |> assign(:garden, garden)
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:nursery_entry, Gardens.get_nursery_entry!(id))}
  end

  defp page_title(:show), do: "Show Nursery entry"
  defp page_title(:edit), do: "Edit Nursery entry"
end
