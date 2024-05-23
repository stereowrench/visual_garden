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
     |> add_plantability(Date.utc_today())
     |> add_current_plants(day)
     |> assign(:extent_dates, extent_dates(garden.tz))}
  end

  def add_plantability(socket, start_date, end_date \\ nil) do
    beds = socket.assigns.beds
    species = VisualGarden.Library.list_species_with_schedule(socket.assigns.garden.region_id)
    schedules_map = Planner.schedules_map(socket.assigns.garden.region_id)
    seeds = Gardens.list_seeds(socket.assigns.garden.id)

    entries =
      for bed <- beds do
        for k <- 0..(bed.length * bed.width - 1) do
          square = k

          end_date =
            if end_date, do: end_date, else: Planner.get_end_date(square, bed, start_date)

          Planner.get_plantables_from_garden(
            bed,
            start_date,
            end_date,
            Date.utc_today(),
            species,
            schedules_map,
            seeds,
            socket.assigns.garden
          )
          |> case do
            [] -> {bed.id, square, false}
            _ -> {bed.id, square, true}
          end
        end
      end
      |> List.flatten()

    entries =
      entries
      |> Enum.group_by(fn {bid, _square, _tf} ->
        bid
      end)
      |> Enum.map(fn {bid, bsf} ->
        {bid,
         Enum.group_by(bsf, fn {_, square, _tf} -> square end)
         |> Enum.map(fn {a, [{_, _square, tf}]} -> {a, tf} end)
         |> Enum.into(%{})}
      end)
      |> Enum.into(%{})

    socket
    |> assign(:plantability, entries)
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

  defp get_end_date(squares, bed, start_date) do
    ed_list =
      for square <- squares do
        Planner.get_end_date(square, bed, start_date)
      end
      |> Enum.reject(&is_nil(&1))
      |> Enum.sort(Date)
      |> Enum.take(1)

    if ed_list == [] do
      nil
    else
      hd(ed_list)
    end
  end

  def add_params(socket, %{"bed_id" => bid, "squares" => sq} = params) do
    bed = Gardens.get_product!(bid)
    start_date = if params["start_date"], do: Date.from_iso8601!(params["start_date"])
    start_date = start_date || Date.utc_today()

    end_date = get_end_date(sq, bed, start_date)

    plantables =
      Planner.get_plantables_from_garden(
        bed,
        start_date,
        end_date,
        Date.utc_today()
      )

    socket
    |> assign(:squares, sq)
    |> assign(:square, nil)
    |> assign(:end_date, end_date)
    |> assign(:bed, bed)
    |> assign(:start_date, start_date)
    |> assign(:planner_entry, nil)
    |> assign(:plantables, plantables)
  end

  def add_params(socket, %{"bed_id" => bid, "square" => sq, "entry" => planner_entry_id} = params) do
    bed = Gardens.get_product!(bid)
    start_date = if params["start_date"], do: Date.from_iso8601!(params["start_date"])
    start_date = start_date || Date.utc_today()

    socket
    |> assign(:bed, Gardens.get_product!(bid))
    |> assign(:square, sq)
    |> assign(:squares, nil)
    |> assign(:bed, bed)
    |> assign(:planner_entry, Planner.get_planner_entry!(planner_entry_id))
    |> assign(:end_date, Planner.get_end_date(sq, bed, start_date))
    |> assign(:start_date, nil)
    |> assign(:plantables, [])
  end

  def add_params(socket, %{"bed_id" => bid, "square" => sq} = params) do
    bed = Gardens.get_product!(bid)
    start_date = if params["start_date"], do: Date.from_iso8601!(params["start_date"])
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
    |> assign(:squares, nil)
    |> assign(:end_date, Planner.get_end_date(sq, bed, start_date))
    |> assign(:start_date, start_date)
    |> assign(:planner_entry, nil)
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
  defp page_title(:new_bulk), do: "New Plans"

  @impl true
  def handle_info({VisualGardenWeb.PlannerLive.FormComponent, {:saved, _plant}}, socket) do
    start_date = Date.utc_today()

    socket =
      socket
      |> add_plantability(start_date)
      |> add_current_plants(start_date)

    {:noreply, socket}
  end

  @impl true
  def handle_event("plant_combo", %{"Square" => squares, "bed_id" => bed_id}, socket) do
    {:noreply,
     socket
     |> push_patch(
       to: ~p"/planners/#{socket.assigns.garden.id}/#{bed_id}/new?#{[squares: squares]}"
     )}
  end

  @impl true
  def handle_event("plant_combo_update", %{"Square" => squares, "bed_id" => bed_id}, socket) do
    bed = Gardens.get_product!(bed_id)
    end_date = get_end_date(squares, bed, Date.utc_today())
    {:noreply, add_plantability(socket, Date.utc_today(), end_date)}
  end

  @impl true
  def handle_event("plant_combo_update", %{"bed_id" => _bed_id}, socket) do
    end_date = nil
    {:noreply, add_plantability(socket, Date.utc_today(), end_date)}
  end

  @impl true
  def handle_event("delete", %{"id" => planner_id} = params, socket) do
    planner = Planner.get_planner_entry!(planner_id)
    Planner.delete_planner_entry(planner)

    start_date = if params["start_date"], do: Date.from_iso8601!(params["start_date"])
    start_date = start_date || Date.utc_today()

    socket =
      socket
      |> add_plantability(start_date)
      |> add_current_plants(start_date)

    {:noreply,
     socket
     |> add_entries()
     |> put_notification(Normal.new(:info, "Successfully deleted planner entry"))
     |> push_patch(to: ~p"/planners/#{socket.assigns.garden.id}")}
  end
end
