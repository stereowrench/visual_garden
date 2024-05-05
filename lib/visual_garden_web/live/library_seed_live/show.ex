defmodule VisualGardenWeb.LibrarySeedLive.Show do
  use VisualGardenWeb, :live_view

  alias VisualGarden.Library

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:library_seed, Library.get_library_seed!(id))}
  end

  defp page_title(:show), do: "Show Library seed"
  defp page_title(:edit), do: "Edit Library seed"
end
