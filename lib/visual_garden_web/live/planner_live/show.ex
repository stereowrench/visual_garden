defmodule VisualGardenWeb.PlannerLive.Show do
  alias VisualGarden.Gardens
  use VisualGardenWeb, :live_view

  alias VisualGarden.Library

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"garden_id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:planner_entries, stub_planner_entries())
     |> assign(:garden, Gardens.get_garden!(id))}
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

  defp page_title(:show), do: "Show Planner"
  defp page_title(:edit), do: "Edit Planner"
end
