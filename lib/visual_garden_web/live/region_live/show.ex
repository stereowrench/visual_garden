defmodule VisualGardenWeb.RegionLive.Show do
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
     |> assign(:can_modify?, Authorization.can_modify_library?(socket.assigns.current_user))
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:region, Library.get_region!(id))}
  end

  defp page_title(:show), do: "Show Region"
  defp page_title(:edit), do: "Edit Region"
end
