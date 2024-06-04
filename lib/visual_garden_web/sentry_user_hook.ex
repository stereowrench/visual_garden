defmodule VisualGardenWeb.SentryUserHook do
  def on_mount(:default, _params, _session, socket) do
    user_id =
      if u = socket.assigns.current_user do
        u.id
      else
        nil
      end

    Sentry.Context.set_user_context(%{user_id: user_id})

    {:cont, socket}
  end
end
