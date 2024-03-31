defmodule VisualGardenWeb.ProductsLive.Index do
  use VisualGardenWeb, :live_view

  alias VisualGarden.Gardens
  alias VisualGarden.Gardens.Products

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :products_collection, Gardens.list_products())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Products")
    |> assign(:products, Gardens.get_products!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Products")
    |> assign(:products, %Products{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Products")
    |> assign(:products, nil)
  end

  @impl true
  def handle_info({VisualGardenWeb.ProductsLive.FormComponent, {:saved, products}}, socket) do
    {:noreply, stream_insert(socket, :products_collection, products)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    products = Gardens.get_products!(id)
    {:ok, _} = Gardens.delete_products(products)

    {:noreply, stream_delete(socket, :products_collection, products)}
  end
end
