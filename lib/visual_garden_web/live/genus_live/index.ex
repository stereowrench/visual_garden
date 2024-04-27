defmodule VisualGardenWeb.GenusLive.Index do
  use VisualGardenWeb, :live_view

  alias VisualGarden.Library
  alias VisualGarden.Library.Genus

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :genera, Library.list_genera())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Genus")
    |> assign(:genus, Library.get_genus!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Genus")
    |> assign(:genus, %Genus{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Genera")
    |> assign(:genus, nil)
  end

  @impl true
  def handle_info({VisualGardenWeb.GenusLive.FormComponent, {:saved, genus}}, socket) do
    {:noreply, stream_insert(socket, :genera, genus)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    genus = Library.get_genus!(id)
    {:ok, _} = Library.delete_genus(genus)

    {:noreply, stream_delete(socket, :genera, genus)}
  end
end
