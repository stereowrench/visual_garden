defmodule VisualGardenWeb.HomeBadge do
  alias VisualGarden.MyDateTime
  alias VisualGarden.Planner
  use VisualGardenWeb, :live_view

  def on_mount(:default, _params, _session, socket) do
    {:cont,
     socket
     |> attach_hook(:home_badge, :handle_params, &set_home_badge/3)}
  end

  defp set_home_badge(_params, _url, socket) do
    socket = badge_socket(socket)
    {:cont, socket}
  end

  # TODO delme
  def badge_socket(socket) do
    socket |> assign(:home_badge, 0) |> assign(:badge_map, %{})
  end

  def badge_socket(socket) do
    todo_items =
      if socket.assigns.current_user do
        Planner.get_todo_items(socket.assigns.current_user)
      else
        []
      end

    badge_map =
      todo_items
      |> Enum.group_by(& &1.garden_id)
      |> Enum.map(fn {group, items} ->
        items =
          Enum.filter(items, &(Timex.compare(MyDateTime.utc_today(), &1.date) <= 0))

        item =
          %{
            beds: Enum.filter(items, &(&1.type in ["media", "water"])) |> length(),
            plants:
              Enum.filter(
                items,
                &(&1.type in [
                    "plant",
                    "plant_overdue",
                    "nursery_plant",
                    "nursery_overdue",
                    "orphaned_nursery",
                    "refuse"
                  ])
              )
              |> length()
          }

        {group, item}
      end)
      |> Enum.into(%{})

    socket |> assign(home_badge: length(todo_items)) |> assign(:badge_map, badge_map)
  end
end
