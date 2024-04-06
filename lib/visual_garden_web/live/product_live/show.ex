defmodule VisualGardenWeb.ProductLive.Show do
  use VisualGardenWeb, :live_view

  alias VisualGarden.Gardens

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"garden_id" => garden_id, "id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:product, Gardens.get_product!(id))
     |> assign(:product_all, Gardens.list_products(garden_id))
     |> assign(:garden, Gardens.get_garden!(garden_id))}
  end

  defp page_title(:show), do: "Show product"
  defp page_title(:edit), do: "Edit product"
end
