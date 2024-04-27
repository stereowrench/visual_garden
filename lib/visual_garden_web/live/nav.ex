defmodule VisualGardenWeb.Nav do
  use VisualGardenWeb, :live_view

  alias VisualGardenWeb.ProductLive
  alias VisualGardenWeb.GardenLive

  def on_mount(:default, _params, _session, socket) do
    {:cont,
     socket
     |> attach_hook(:active_tab, :handle_params, &set_active_tab/3)}
  end

  defp set_active_tab(_params, _url, socket) do
    active_tab =
      case {socket.view, socket.assigns.live_action} do
        {sv, _} when sv in [ProductLive.Show, ProductLive.Index] ->
          :products

        {sv, _} when sv in [GardenLive.Index, GardenLive.Show] ->
          :gardens

        {_, _} ->
          nil
      end
    {:cont, assign(socket, active_tab: active_tab)}
  end
end
