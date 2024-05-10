defmodule VisualGardenWeb.PlannerLive.Show do
  alias VisualGarden.Planner
  alias VisualGarden.Gardens
  use VisualGardenWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"garden_id" => id} = params, _, socket) do
    garden = Gardens.get_garden!(id)

    {:noreply,
     socket
     |> add_params(params)
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:garden, garden)
     |> add_entries()
     |> assign(:beds, Gardens.list_beds(id))
     |> assign(:extent_dates, extent_dates(garden.tz))}
  end

  defp add_entries(socket) do
    entries = Planner.list_planner_entries(socket.assigns.garden.id)

    socket
    |> assign(
      :planner_entries,
      entries
    )
  end

  def add_params(socket, %{"bed_id" => bid, "square" => sq, "start_date" => start_date}) do
    bed = Gardens.get_product!(bid)
    start_date = if start_date, do: Date.from_iso8601!(start_date)
    start_date = start_date || Date.utc_today()

    plantables =
      Planner.get_plantables_from_garden(
        bed,
        start_date,
        Planner.get_end_date(sq, bed, start_date),
        Date.utc_today()
      )

    socket
    |> assign(:bed, Gardens.get_product!(bid))
    |> assign(:square, sq)
    |> assign(:start_date, start_date)
    |> assign(:plantables, plantables)
  end

  def add_params(socket, _) do
    socket
  end

  def extent_dates(tz) do
    now =
      DateTime.utc_now()
      |> Timex.Timezone.convert(tz)
      |> Timex.to_date()

    start_d = Timex.shift(now, days: -180) |> Timex.beginning_of_month()
    end_d = Timex.shift(now, days: 365) |> Timex.end_of_month()
    {start_d, end_d}
  end

  defp page_title(:show), do: "Show Planner"
  defp page_title(:new), do: "New Planner"
  defp page_title(:edit), do: "Edit Planner"

  def handle_info({VisualGardenWeb.PlannerLive.FormComponent, {:saved, _plant}}, socket) do
    {:noreply, socket}
  end
end
