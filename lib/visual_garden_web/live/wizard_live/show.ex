defmodule VisualGardenWeb.WizardLive.Show do
  use VisualGardenWeb, :live_view


  @impl true
  def mount(_params, _session, socket) do
    IO.inspect(socket)
    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))}
  end

  defp page_title(:show), do: "Show Wizard"
end
