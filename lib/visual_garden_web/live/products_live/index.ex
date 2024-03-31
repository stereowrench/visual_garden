defmodule VisualGardenWeb.ProductLive.Index do
  use VisualGardenWeb, :live_view

  alias VisualGarden.Gardens
  alias VisualGarden.Gardens.Product

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :product_collection, Gardens.list_products())}
  end

  @impl true
  @spec handle_params(any(), any(), %{
          :assigns => atom() | %{:live_action => :edit | :index | :new, optional(any()) => any()},
          optional(any()) => any()
        }) :: {:noreply, map()}
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit product")
    |> assign(:product, Gardens.get_product!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New product")
    |> assign(:product, %Product{})
  end

  defp apply_action(socket, :index, _params) do
    socket
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
