defmodule VisualGardenWeb.GardenLive.Show do
  use VisualGardenWeb, :live_view

  alias VisualGarden.Gardens

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:garden, Gardens.get_garden!(id))
     |> assign(:seeds, Gardens.list_seeds(id))
     |> assign_plants()
     |> assign(:products, Gardens.list_products(id))}
  end

  defp page_title(:show), do: "Show Garden"
  defp page_title(:edit), do: "Edit Garden"
  defp page_title(:plant), do: "Plant"

  @impl true
  def handle_info({VisualGardenWeb.GardenLive.FormComponent, {:saved, garden}}, socket) do
    {:noreply, assign(socket, :garden, garden)}
  end

  def handle_info({VisualGardenWeb.PlantLive.FormComponent, {:saved, _plant}}, socket) do
    {:noreply, assign_plants(socket)}
  end

  defp assign_plants(socket) do
    plants = Gardens.list_plants(socket.assigns.garden.id)

    total_plants =
      plants
      |> Enum.map(& &1.qty)
      |> Enum.sum()

    socket
    |> assign(:plants, plants)
    |> assign(:total_plants, total_plants)
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

  def months_in_extent({start_d, end_d}) do
    Timex.diff(end_d, start_d, :months)
  end

  def generate_months(tz) do
    days = {start_d, _} = extent_dates(tz)

    for mo <- 1..months_in_extent(days) do
      ed =
        start_d
        |> Timex.shift(months: mo - 1)

      days_in_month =
        ed |> Timex.days_in_month()

      month_name = Timex.month_shortname(ed.month)

      %{
        days_in_month: days_in_month,
        month_name: month_name,
        mo_num: mo
      }
    end
  end

  def x_shift(mo, tz) do
    {start_d, _end_d} = extent_dates(tz)

    beg = start_d

    en =
      start_d
      |> Timex.shift(months: mo - 1)
      |> Timex.shift(days: -1)
      |> Timex.end_of_month()

    Timex.diff(en, beg, :days)
  end

  def x_shift_date(date, tz) do
    {start_d, _} = extent_dates(tz)
    Timex.diff(date, start_d, :days)
  end

  def clamp_date(start, en, date) do
    case Timex.diff(date, start, :days) do
      b when b > 0 ->
        case Timex.diff(en, date) do
          c when c > 0 -> date
          _ -> en
        end
      _ -> start
    end
  end

  @num_squares 3

  def stub_planner_entries do
    [
      %{
        crop_name: "Corn",
        plant_date: ~D[2024-04-03],
        bed: 1,
        square: 2,
        days_to_maturation: 90,
        id: -3
      }
    ]
  end

  defp generate_available_regions(entries) do
    grouped =
      entries
      |> Enum.group_by(& &1.square)

    grouped =
      Enum.map(1..@num_squares, fn
        square_num ->
          case grouped[square_num] do
            nil -> {square_num, []}
            _el -> {square_num, grouped[square_num]}
          end
      end)
      |> Enum.into(%{})

    for {group, es} <- grouped, into: %{} do
      plant_dates = Enum.map(es, & &1.plant_date)
      days = Enum.map(es, & &1.days_to_maturation)

      pairs =
        for {date, days} <- Enum.zip(plant_dates, days), do: [date, Timex.shift(date, days: days)]

      pairs = List.flatten(pairs)

      new_list =
        ([Date.new!(DateTime.utc_now().year, 1, 1)] ++
           pairs ++ [Timex.end_of_year(DateTime.utc_now().year)])

      chunks = Enum.chunk_every(new_list, 2)

      spans =
        for [a, b] <- chunks do
          %{
            start_date: a,
            finish_date: b
          }
        end

      {group, spans}
    end
  end
end
