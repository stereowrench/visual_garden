defmodule VisualGardenWeb.NurseryEntryLive.Index do
  use VisualGardenWeb, :live_view

  alias VisualGarden.Gardens
  alias VisualGarden.Gardens.NurseryEntry

  @impl true
  def mount(%{"garden_id" => garden_id}, _session, socket) do
    garden = Gardens.get_garden!(garden_id)

    {:ok,
     socket
     |> stream(
       :nursery_entries,
       Gardens.list_nursery_entries(garden_id) |> assign(:garden, garden)
     )}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Nursery entry")
    |> assign(:nursery_entry, Gardens.get_nursery_entry!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Nursery entry")
    |> assign(:nursery_entry, %NurseryEntry{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Nursery entries")
    |> assign(:nursery_entry, nil)
  end

  @impl true
  def handle_info(
        {VisualGardenWeb.NurseryEntryLive.FormComponent, {:saved, nursery_entry}},
        socket
      ) do
    {:noreply, stream_insert(socket, :nursery_entries, nursery_entry)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    nursery_entry = Gardens.get_nursery_entry!(id)
    {:ok, _} = Gardens.delete_nursery_entry(nursery_entry)

    {:noreply, stream_delete(socket, :nursery_entries, nursery_entry)}
  end
end
