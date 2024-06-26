defmodule VisualGardenWeb.SpeciesLive.Index do
  use VisualGardenWeb, :live_view

  alias VisualGarden.Library
  alias VisualGarden.Library.Species

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:can_modify?, Authorization.can_modify_library?(socket.assigns.current_user))
     |> assign(:common_names, Library.list_species_with_common_names() |> Enum.into(%{}))
     |> stream(:species_collection, Library.list_species())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp get_common_name(common_names, species) do
    common_names[species]
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
    Authorization.authorize_library(socket.assigns.current_user)
    species = Library.get_species!(id)
    {:ok, _} = Library.delete_species(species)

    {:noreply, stream_delete(socket, :species_collection, species)}
  end
end
