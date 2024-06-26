defmodule VisualGardenWeb.HomeLive.Show do
  use VisualGardenWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if socket.assigns.current_user do
      {:ok, socket |> assign(:disable_home_badge, true)}
    else
      {:ok, socket |> redirect(to: ~p"/")}
    end
  end

  @impl true
  def handle_params(_params, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, "Home")}
  end
end
