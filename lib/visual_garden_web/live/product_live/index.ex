defmodule VisualGardenWeb.ProductLive.Index do
  alias VisualGarden.Repo
  alias VisualGardenWeb.HomeBadge
  alias VisualGarden.MyDateTime
  alias VisualGarden.Planner
  alias VisualGarden.Authorization.UnauthorizedError
  use VisualGardenWeb, :live_view

  alias VisualGarden.Gardens
  alias VisualGarden.Gardens.Product

  @impl true
  def mount(%{"garden_id" => garden_id}, _session, socket) do
    Authorization.authorize_garden_view(garden_id, socket.assigns.current_user)
    garden = Gardens.get_garden!(garden_id)

    {:ok,
     socket
     |> assign(:garden_id, garden_id)
     |> assign(
       :can_modify?,
       Authorization.can_modify_garden?(
         garden,
         socket.assigns.current_user
       )
     )
     |> assign_actions()
     |> assign_products()}
  end

  defp assign_actions(socket) do
    if socket.assigns.live_action in [:beds, :transfer, :water] do
      todos =
        Planner.get_todo_items(socket.assigns.current_user)
        |> Enum.filter(&(Timex.compare(MyDateTime.utc_today(), &1.date) <= 0))
        |> Enum.filter(
          &(&1.type in ["media", "water"] && to_string(&1.garden_id) == socket.assigns.garden_id)
        )
        |> Enum.group_by(& &1.bed.id)

      assign(socket, :todos, todos)
    else
      assign(socket, :todos, %{})
    end
  end

  defp assign_products(socket) do
    products =
      Gardens.list_products(socket.assigns.garden_id)

    products =
      if socket.assigns.live_action in [:beds, :new_bed, :edit_bed, :transfer, :water] do
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
    bed = Gardens.get_product!(id)
    garden = Gardens.get_garden!(garden_id)

    unless garden.id == bed.garden_id do
      raise UnauthorizedError
    end

    socket
    |> assign(:garden, garden)
    |> assign(:page_title, "Edit product")
    |> assign(:product, bed)
  end

  defp apply_action(socket, :edit_bed, %{"garden_id" => garden_id, "id" => id}) do
    bed = Gardens.get_product!(id)
    garden = Gardens.get_garden!(garden_id)

    unless garden.id == bed.garden_id do
      raise UnauthorizedError
    end

    socket
    |> assign(:garden, garden)
    |> assign(:page_title, "Edit bed")
    |> assign(:product, bed)
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

  defp apply_action(socket, :water, %{"garden_id" => garden_id, "id" => bed_id}) do
    bed = Gardens.get_product!(bed_id)
    garden = Gardens.get_garden!(garden_id)

    unless bed.garden_id == garden.id do
      raise UnauthorizedError
    end

    socket
    |> assign(:garden, garden)
    |> assign(:page_title, "watering bed")
    |> assign(:product, bed)
  end

  defp apply_action(socket, :transfer, %{"garden_id" => garden_id, "id" => id}) do
    garden = Gardens.get_garden!(garden_id)

    avail_products =
      Gardens.list_products(socket.assigns.garden_id)
      |> Enum.filter(&(&1.type in [:growing_media, :compost]))

    product = Gardens.get_product!(id)

    if product.garden_id != garden.id do
      raise UnauthorizedError
    end

    socket
    |> assign(:garden, garden)
    |> assign(:avail_products, avail_products)
    |> assign(:page_title, "Transferring")
    |> assign(:product, product)
  end

  defp apply_action(socket, :index, %{"garden_id" => garden_id}) do
    socket
    |> assign(:garden, Gardens.get_garden!(garden_id))
    |> assign(:page_title, "Listing product")
    |> assign(:product, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    Authorization.authorize_garden_modify(socket.assigns.garden_id, socket.assigns.current_user)
    product = Gardens.get_product!(id)

    unless product.garden_id == socket.assigns.garden.id do
      raise UnauthorizedError
    end

    {:ok, _} = Gardens.delete_product(product)

    {:noreply, assign_products(socket)}
  end

  @impl true
  def handle_event("water", %{"bed_id" => bid}, socket) do
    Repo.transaction(fn ->
      bed = Gardens.get_product!(bid)
      garden = Gardens.get_garden!(bed.garden_id)
      Authorization.authorize_garden_modify(garden.id, socket.assigns.current_user)

      {:ok, _} =
        Gardens.create_event_log("water", %{
          "event_time" => MyDateTime.utc_now(),
          "product_id" => bid
        })
    end)

    {:noreply,
     HomeBadge.badge_socket(socket)
     |> assign_products()
     |> assign_actions()
     |> push_patch(to: ~p"/gardens/#{socket.assigns.garden.id}/beds")}
  end

  @impl true
  def handle_event("humidity", %{"bed_id" => bid}, socket) do
    Repo.transaction(fn ->
      bed = Gardens.get_product!(bid)
      garden = Gardens.get_garden!(bed.garden_id)
      Authorization.authorize_garden_modify(garden.id, socket.assigns.current_user)

      {:ok, _} =
        Gardens.create_event_log("humidity", %{
          "event_time" => MyDateTime.utc_now(),
          "product_id" => bid
        })
    end)

    {:noreply,
     HomeBadge.badge_socket(socket)
     |> assign_products()
     |> assign_actions()
     |> push_patch(to: ~p"/gardens/#{socket.assigns.garden.id}/beds")}
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

  @impl true
  def handle_info({VisualGardenWeb.EventLogLive.FormComponent, {:saved, _event_log}}, socket) do
    {:noreply, socket |> assign_actions() |> assign_products()}
  end

  @impl true
  def handle_info({VisualGardenWeb.ProductLive.FormComponent, {:saved, _product}}, socket) do
    {:noreply, socket |> assign_actions() |> assign_products()}
  end
end
