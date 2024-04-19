defmodule VisualGardenWeb.SeedLive.Show do
  use VisualGardenWeb, :live_view

  alias VisualGarden.Gardens

  @impl true
  def mount(%{"garden_id" => garden_id}, _session, socket) do
    {:ok, assign(socket, :garden, Gardens.get_garden!(garden_id))}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:seed, Gardens.get_seed!(id))}
  end

  defp page_title(:show), do: "Show Seed"
  defp page_title(:edit), do: "Edit Seed"
end
