defmodule VisualGardenWeb.PlantLive.Show do
  alias VisualGarden.Authorization.UnauthorizedError
  use VisualGardenWeb, :live_view

  alias VisualGarden.Gardens

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def page_tip() do
    assigns = %{}

    ~H"""
    You should expect to see growth in <b>10 days</b> after planting.
    """
  end

  @impl true
  def handle_params(
        %{"garden_id" => garden_id, "product_id" => product_id, "id" => id},
        _,
        socket
      ) do
    garden = Gardens.get_garden!(garden_id)
    Authorization.authorize_garden_view(garden.id, socket.assigns.current_user)
    plant = Gardens.get_plant!(id)

    product = Gardens.get_product!(product_id)

    unless product.garden_id == garden.id do
      raise UnauthorizedError
    end

    unless plant.product_id == product.id do
      raise UnauthorizedError
    end

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     #  |> assign(:page_tip_title, "Gardening recommendations")
     #  |> assign(:page_tip, page_tip())
     |> assign(
       :can_modify?,
       Authorization.can_modify_garden?(garden, socket.assigns.current_user)
     )
     |> assign(:garden, garden)
     |> assign(:product, product)
     |> assign(:plant, plant)
     |> assign(:events, Gardens.list_event_logs(product_id, id))}
  end

  defp page_title(:show), do: "Show Plant"
  defp page_title(:edit), do: "Edit Plant"

  @impl true
  def handle_event("archive", _, socket) do
    Authorization.authorize_garden_modify(socket.assigns.garden.id, socket.assigns.current_user)
    {:ok, _} = Gardens.archive_plant(socket.assigns.plant)
    {:noreply, socket |> assign(:plant, Gardens.get_plant!(socket.assigns.plant.id))}
  end

  @impl true
  def handle_info({VisualGardenWeb.PlantLive.FormComponent, {:saved, plant}}, socket) do
    {:noreply,
     socket
     |> assign(:plant, plant)
     |> assign(:events, Gardens.list_event_logs(plant.product_id, plant.id))}
  end
end
