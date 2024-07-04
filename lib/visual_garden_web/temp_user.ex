defmodule VisualGardenWeb.TempUser do
  alias VisualGarden.Wizard
  use VisualGardenWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  def on_mount(:mount_temp_user, _params, session, socket) do
    {:cont, mount_temp_user(socket, session)}
  end

  def mount_temp_user(socket, session) do
    out =
      if id = session["temp_user_id"] do
        {:ok, Wizard.get_temp_user(id)}
      else
        if session["user_user_token"] do
          nil
        else
          Phoenix.LiveView.attach_hook(socket, :set_current_path, :handle_params, fn
            _params, url, socket ->
              {:halt,
               socket
               |> Phoenix.LiveView.push_navigate(to: ~p"/assign_temp_user?#{[return: url]}")}
          end)
        end
      end

    case out do
      {:ok, user} ->
        Phoenix.Component.assign_new(socket, :temp_user, fn ->
          user
        end)

      el ->
        el
    end
  end
end
