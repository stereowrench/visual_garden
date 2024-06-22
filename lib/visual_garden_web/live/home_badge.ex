defmodule VisualGardenWeb.HomeBadge do
  alias VisualGarden.Planner
  use VisualGardenWeb, :live_view

  def on_mount(:default, _params, _session, socket) do
    {:cont,
     socket
     |> attach_hook(:home_badge, :handle_params, &set_home_badge/3)}
  end

  defp set_home_badge(_params, _url, socket) do
    todo_items =
      if socket.assigns.current_user do
        Planner.get_todo_items(socket.assigns.current_user)
      else
        []
      end

    {:cont, assign(socket, home_badge: length(todo_items))}
  end
end
