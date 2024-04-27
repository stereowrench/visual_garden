defmodule VisualGardenWeb.SpeciesLive.Index do
  use VisualGardenWeb, :live_view

  alias VisualGarden.Library
  alias VisualGarden.Library.Species

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :species_collection, Library.list_species())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Species")
    |> assign(:species, Library.get_species!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Species")
    |> assign(:species, %Species{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Species")
    |> assign(:species, nil)
  end

  @impl true
  def handle_info({VisualGardenWeb.SpeciesLive.FormComponent, {:saved, species}}, socket) do
    {:noreply, stream_insert(socket, :species_collection, species)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    species = Library.get_species!(id)
    {:ok, _} = Library.delete_species(species)

    {:noreply, stream_delete(socket, :species_collection, species)}
  end
end
