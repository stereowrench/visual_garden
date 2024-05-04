defmodule VisualGardenWeb.ProductLive.Index do
  use VisualGardenWeb, :live_view

  alias VisualGarden.Gardens
  alias VisualGarden.Gardens.Product

  @impl true
  def mount(%{"garden_id" => garden_id}, _session, socket) do
    {:ok,
     socket
     |> assign(:garden_id, garden_id)
     |> assign_products()}
  end

  defp assign_products(socket) do
    products =
      Gardens.list_products(socket.assigns.garden_id)

    products =
      if socket.assigns.live_action in [:beds, :new_bed, :edit_bed] do
        Enum.filter(products, &(&1.type == :bed))
      else
        Enum.reject(products, &(&1.type == :bed))
      end

    socket
    |> assign(:products, products)
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

  defp apply_action(socket, :edit_bed, %{"garden_id" => garden_id, "id" => id}) do
    socket
    |> assign(:garden, Gardens.get_garden!(garden_id))
    |> assign(:page_title, "Edit bed")
    |> assign(:product, Gardens.get_product!(id))
  end

  defp apply_action(socket, :new, %{"garden_id" => garden_id}) do
    socket
    |> assign(:garden, Gardens.get_garden!(garden_id))
    |> assign(:page_title, "New product")
    |> assign(:product, %Product{garden_id: garden_id})
  end

  defp apply_action(socket, :new_bed, %{"garden_id" => garden_id}) do
    socket
    |> assign(:garden, Gardens.get_garden!(garden_id))
    |> assign(:page_title, "New bed")
    |> assign(:product, %Product{garden_id: garden_id})
  end

  defp apply_action(socket, :beds, %{"garden_id" => garden_id}) do
    socket
    |> assign(:garden, Gardens.get_garden!(garden_id))
    |> assign(:page_title, "Listing beds")
    |> assign(:product, nil)
  end

  defp apply_action(socket, :index, %{"garden_id" => garden_id}) do
    socket
    |> assign(:garden, Gardens.get_garden!(garden_id))
    |> assign(:page_title, "Listing product")
    |> assign(:product, nil)
  end

  @impl true
  def handle_info({VisualGardenWeb.ProductLive.FormComponent, {:saved, _product}}, socket) do
    {:noreply, assign_products(socket)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    product = Gardens.get_product!(id)
    {:ok, _} = Gardens.delete_product(product)

    {:noreply, assign_products(socket)}
  end

  def friendly_type(name) do
    Product.friendly_type(name)
  end

  def name_str(product) do
    case product.type do
      :bed -> "#{product.name} (#{product.length}x#{product.width})"
      _ -> product.name
    end
  end
end
