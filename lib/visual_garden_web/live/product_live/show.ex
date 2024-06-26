defmodule VisualGardenWeb.ProductLive.Show do
  use VisualGardenWeb, :live_view

  alias VisualGarden.Gardens
  alias VisualGarden.Planner

  @impl true
  def mount(%{"id" => _id}, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"garden_id" => garden_id, "id" => id, "square" => square}, _, socket) do
    product = Gardens.get_product!(id)

    Authorization.authorize_garden_view(garden_id, socket.assigns.current_user)

    {row, column} = Planner.parse_square(square, product)

    els = Gardens.list_event_logs(id, nil, row, column)
    socket = assign(socket, :events, els)

    grouped_plants =
      Gardens.list_plants(garden_id, id)
      |> Enum.reject(& &1.archived)
      |> Enum.group_by(fn plant ->
        Gardens.row_col_to_square(plant.row, plant.column, product)
      end)

    garden = Gardens.get_garden!(garden_id)

    {:noreply,
     socket
     |> assign(
       :can_modify?,
       Authorization.can_modify_garden?(garden, socket.assigns.current_user)
     )
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:product, product)
     |> assign(:row, row)
     |> assign(:column, column)
     |> assign(:grouped_plants, grouped_plants)
     |> assign(:products, Gardens.list_products(garden_id))
     |> assign(:plants, Gardens.list_plants(garden_id, id, row, column))
     |> assign(:garden, garden)}
  end

  @impl true
  def handle_params(%{"garden_id" => garden_id, "id" => id}, _, socket) do
    Authorization.authorize_garden_view(garden_id, socket.assigns.current_user)
    els = Gardens.list_event_logs(id)
    socket = assign(socket, :events, els)

    product = Gardens.get_product!(id)

    grouped_plants =
      Gardens.list_plants(garden_id, id)
      |> Enum.reject(& &1.archived)
      |> Enum.group_by(fn plant ->
        Gardens.row_col_to_square(plant.row, plant.column, product)
      end)

    garden = Gardens.get_garden!(garden_id)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:product, product)
     |> assign(:row, nil)
     |> assign(
       :can_modify?,
       Authorization.can_modify_garden?(garden, socket.assigns.current_user)
     )
     |> assign(:column, nil)
     |> assign(:grouped_plants, grouped_plants)
     |> assign(:products, Gardens.list_products(garden_id))
     |> assign(:plants, Gardens.list_plants(garden_id, id))
     |> assign(:garden, garden)}
  end

  @impl true
  def handle_info({VisualGardenWeb.EventLogLive.FormComponent, {:saved, _event_log}}, socket) do
    events = Gardens.list_event_logs(socket.assigns.product.id)
    {:noreply, assign(socket, :events, events)}
  end

  def handle_info({VisualGardenWeb.ProductLive.BedBulkComponent, :bulk_saved}, socket) do
    events = Gardens.list_event_logs(socket.assigns.product.id)
    {:noreply, assign(socket, :events, events)}
  end

  def handle_info({VisualGardenWeb.ProductLive.FormComponent, {:saved, product}}, socket) do
    {:noreply, assign(socket, :product, product)}
  end

  def selected?(val, row, col, bed) do
    if !row or !col do
      ""
    else
      if val == Gardens.row_col_to_square(row, col, bed) do
        " selected"
      else
        ""
      end
    end
  end

  @names %{
    "water" => "watered",
    "till" => "tilled"
  }

  @impl true
  def handle_event(evt, %{}, socket) when evt in ["water", "till"] do
    Authorization.authorize_garden_modify(socket.assigns.garden.id, socket.assigns.current_user)

    {:ok, _event} =
      Gardens.create_event_log(evt, %{
        "event_type" => evt,
        "event_time" => VisualGarden.MyDateTime.utc_now(),
        "product_id" => socket.assigns.product.id
      })

    {:noreply,
     socket
     |> assign(:events, Gardens.list_event_logs(socket.assigns.product.id))
     |> put_notification(Normal.new(:info, "#{socket.assigns.product.name} was #{@names[evt]}"))}
  end

  defp page_title(:show), do: "Show product"
  defp page_title(:show_bed), do: "Show bed"
  defp page_title(:edit), do: "Edit product"
  defp page_title(:show_square), do: "Show square"
  defp page_title(:new_water), do: "Watering"
  defp page_title(:till), do: "Tilling"
  defp page_title(:transfer), do: "Amend"
  defp page_title(:bulk_weed), do: "Weed"
  defp page_title(:bulk_trim), do: "Trim"
  defp page_title(:bulk_harvest), do: "Harvest"
  defp page_title(:edit_bed), do: "Edit bed"
  defp page_title(:new_water_bed), do: "Water bed"
  defp page_title(:till_bed), do: "Till bed"
  defp page_title(:transfer_bed), do: "Amend bed"

  defp last_watered(events) do
    events
    |> last_watered_dt()
    |> case do
      nil -> "never"
      dt -> Timex.format!(dt, "{relative}", :relative)
    end
  end

  defp last_watered_dt(events) do
    events
    |> Enum.sort_by(& &1.event_time)
    |> Enum.filter(&(&1.event_type == :water))
    |> Enum.take(1)
    |> case do
      [] -> nil
      [%{event_time: dt}] -> dt
    end
  end

  defp modal_cancel(product) do
    if product.type == :bed do
      JS.patch(~p"/gardens/#{product.garden_id}/beds/#{product}")
    else
      JS.patch(~p"/gardens/#{product.garden_id}/products/#{product}")
    end
  end

  defp modal_patch(product) do
    if product.type == :bed do
      ~p"/gardens/#{product.garden_id}/beds/#{product}"
    else
      ~p"/gardens/#{product.garden_id}/products/#{product}"
    end
  end
end
