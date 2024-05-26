defmodule VisualGardenWeb.RegionLive.Index do
  use VisualGardenWeb, :live_view

  alias VisualGarden.Library
  alias VisualGarden.Library.Region

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :regions, Library.list_regions())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> assign(:can_modify?, Authorization.can_modify_library?(socket.assigns.current_user))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Region")
    |> assign(:region, Library.get_region!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Region")
    |> assign(:region, %Region{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Regions")
    |> assign(:region, nil)
  end

  @impl true
  def handle_info({VisualGardenWeb.RegionLive.FormComponent, {:saved, region}}, socket) do
    {:noreply, stream_insert(socket, :regions, region)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    Authorization.authorize_library(socket.assigns.current_user)
    region = Library.get_region!(id)
    {:ok, _} = Library.delete_region(region)

    {:noreply, stream_delete(socket, :regions, region)}
  end
end
