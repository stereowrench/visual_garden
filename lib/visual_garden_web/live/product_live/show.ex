defmodule VisualGardenWeb.ProductLive.Show do
  use VisualGardenWeb, :live_view

  alias VisualGarden.Gardens

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    els = Gardens.list_event_logs(id)
    socket = assign(socket, :events, els)
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"garden_id" => garden_id, "id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:product, Gardens.get_product!(id))
     |> assign(:products, Gardens.list_products(garden_id))
     |> assign(:plants, Gardens.list_plants(garden_id, id))
     |> assign(:garden, Gardens.get_garden!(garden_id))}
  end

  @impl true
  def handle_info({VisualGardenWeb.EventLogLive.FormComponent, {:saved, _event_log}}, socket) do
    {:noreply, assign(socket, :events, Gardens.list_event_logs(socket.assigns.product.id))}
  end

  def handle_info({VisualGardenWeb.ProductLive.FormComponent, {:saved, product}}, socket) do
    {:noreply, assign(socket, :product, product)}
  end

  @names %{
    "water" => "watered",
    "till" => "tilled"
  }

  @impl true
  def handle_event(evt, %{}, socket) when evt in ["water", "till"] do
    {:ok, _event} =
      Gardens.create_event_log(evt, %{
        "event_type" => evt,
        "event_time" => DateTime.utc_now(),
        "product_id" => socket.assigns.product.id
      })

    {:noreply,
     socket
     |> assign(:events, Gardens.list_event_logs(socket.assigns.product.id))
     |> put_notification(Normal.new(:info, "#{socket.assigns.product.name} was #{@names[evt]}"))}
  end

  defp page_title(:show), do: "Show product"
  defp page_title(:edit), do: "Edit product"
  defp page_title(:new_water), do: "Watering"
  defp page_title(:till), do: "Tilling"
  defp page_title(:transfer), do: "Amend"
  defp page_title(:bulk_weed), do: "Weed"
  defp page_title(:bulk_trim), do: "Trim"
  defp page_title(:bulk_harvest), do: "Harvest"

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
