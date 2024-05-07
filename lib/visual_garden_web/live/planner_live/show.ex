defmodule VisualGardenWeb.PlannerLive.Show do
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
     |> assign(:planner_entries, stub_planner_entries())
     |> assign(:beds, Gardens.list_beds(id))
     |> assign(:extent_dates, extent_dates(garden.tz))
     |> assign(:garden, garden)}
  end

  def add_params(socket, %{"bed_id" => bid, "square" => sq, "start_date" => start_date}) do
    socket
    |> assign(:bed, Gardens.get_product!(bid))
    |> assign(:square, sq)
    |> assign(:start_date, Date.from_iso8601!(start_date))
    |> dbg

    # |> assign(:seeds, )
  end

  def add_params(socket, _) do
    socket
  end

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
end
