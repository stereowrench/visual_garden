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
    day = Date.utc_today()

    {:noreply,
     socket
     |> add_params(params)
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:garden, garden)
     |> add_entries()
     |> assign(:beds, Gardens.list_beds(id))
     |> add_current_plants(day)
     |> assign(:extent_dates, extent_dates(garden.tz))}
  end

  def has_plant(plants, idx) do
    (plants[idx] || []) == []
  end

  def content_for_cell(plants, val) do
    plants[val]
  end

  defp add_current_plants(socket, today) do
    plants =
      for bed <- socket.assigns.beds, into: %{} do
        plants =
          for entry <- socket.assigns.planner_entries[bed.id] || [], into: %{} do
            # if it ends before today, filter it out
            # if it starts before today and ends after today, include common_name
            # if it start after today, filter it out
            start = entry.start_plant_date
            en = entry.end_plant_date
            num = VisualGardenWeb.PlannerLive.GraphComponent.bed_square(entry, bed)

            cond do
              Timex.diff(en, today, :days) <= 0 ->
                {num, nil}

              Timex.diff(start, today, :days) <= 0 and Timex.diff(en, today, :days) >= 0 ->
                {num, entry.common_name}

              true ->
                {num, nil}
            end
          end

        {bed.id, plants}
      end

    socket
    |> assign(:plants, plants)
  end

  defp add_entries(socket) do
    entries = Planner.list_planner_entries(socket.assigns.garden.id)

    socket
    |> assign(
      :planner_entries,
      entries
    )
  end

  def add_params(socket, %{"bed_id" => bid, "squares" => sq, "start_date" => start_date}) do
    bed = Gardens.get_product!(bid)
    start_date = if start_date, do: Date.from_iso8601!(start_date)
    start_date = start_date || Date.utc_today()

    for square <- String.split(sq, ",") do
      Planner.get_end_date(square, bed, start_date)
    end

    socket
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
    |> assign(:planner_entry, nil)
    |> assign(:plantables, plantables)
  end

  def add_params(socket, %{"bed_id" => bid, "square" => sq, "entry" => planner_entry_id}) do
    socket
    |> assign(:bed, Gardens.get_product!(bid))
    |> assign(:square, sq)
    |> assign(:planner_entry, Planner.get_planner_entry!(planner_entry_id))
    |> assign(:start_date, nil)
    |> assign(:plantables, [])
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
  defp page_title(:new_bulk), do: "New Plans"

  @impl true
  def handle_info({VisualGardenWeb.PlannerLive.FormComponent, {:saved, _plant}}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("plant_combo", %{"Square" => squares, "bed_id" => bed_id}, socket) do
    {:noreply,
     socket
     |> push_patch(to: ~p"/planners/#{socket.assigns.garden.id}/#{bed_id}/new?#{[squares: squares]}")}
  end

  @impl true
  def handle_event("delete", %{"id" => planner_id}, socket) do
    planner = Planner.get_planner_entry!(planner_id)
    Planner.delete_planner_entry(planner)

    {:noreply,
     socket
     |> add_entries()
     |> put_notification(Normal.new(:info, "Successfully deleted planner entry"))
     |> push_patch(to: ~p"/planners/#{socket.assigns.garden.id}")}
  end
end
