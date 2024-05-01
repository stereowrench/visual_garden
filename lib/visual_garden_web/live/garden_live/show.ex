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

  def x_shift(mo) do
    if mo == 1 do
      0
    else
      start = Date.new!(DateTime.utc_now().year, 1, 1)
      en = Timex.end_of_month(DateTime.utc_now().year, mo - 1)
      Timex.diff(en, start, :days) + 1
    end
  end

  def x_shift_date(date) do
    start = Date.new!(DateTime.utc_now().year, 1, 1)
    Timex.diff(date, start, :days)
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
    # group entires by bed
    # create start, finish pairs
    # add beginning and end of year
    # group by 2s

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
        |> IO.inspect()

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
