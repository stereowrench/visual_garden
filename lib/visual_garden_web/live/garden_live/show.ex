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
     |> assign(:products, Gardens.list_products(id))}
  end

  defp page_title(:show), do: "Show Garden"
  defp page_title(:edit), do: "Edit Garden"


  @impl true
  def handle_info({VisualGardenWeb.GardenLive.FormComponent, {:saved, garden}}, socket) do
    {:noreply, assign(socket, :garden, garden)}
  end
end
