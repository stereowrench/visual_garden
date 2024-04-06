defmodule VisualGardenWeb.ProductLive.Index do
  use VisualGardenWeb, :live_view

  alias VisualGarden.Gardens
  alias VisualGarden.Gardens.Product

  @impl true
  def mount(%{"garden_id" => garden_id}, _session, socket) do
    {:ok, stream(socket, :product_collection, Gardens.list_products(garden_id))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"garden_id" => garden_id, "id" => id}) do
    socket
    |> assign(:garden, Gardens.get_garden!(garden_id))
    |> assign(:page_title, "Edit product")
    |> assign(:product, Gardens.get_product!(id))
  end

  defp apply_action(socket, :new, %{"garden_id" => garden_id}) do
    socket
    |> assign(:garden, Gardens.get_garden!(garden_id))
    |> assign(:page_title, "New product")
    |> assign(:product, %Product{garden_id: garden_id})
  end

  defp apply_action(socket, :index, %{"garden_id" => garden_id}) do
    socket
    |> assign(:garden, Gardens.get_garden!(garden_id))
    |> assign(:page_title, "Listing product")
    |> assign(:product, nil)
  end

  @impl true
  def handle_info({VisualGardenWeb.ProductLive.FormComponent, {:saved, product}}, socket) do
    {:noreply, stream_insert(socket, :product_collection, product)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    product = Gardens.get_product!(id)
    {:ok, _} = Gardens.delete_product(product)

    {:noreply, stream_delete(socket, :product_collection, product)}
  end
end
