defmodule VisualGardenWeb.SeedLive.Show do
  alias VisualGarden.Repo
  alias VisualGarden.Library
  use VisualGardenWeb, :live_view

  alias VisualGarden.Gardens

  @impl true
  def mount(%{"garden_id" => garden_id}, _session, socket) do
    Authorization.authorize_garden_view(garden_id, socket.assigns.current_user)
    garden = Gardens.get_garden!(garden_id)

    {:ok,
     socket
     |> assign(
       :can_modify?,
       Authorization.can_modify_garden?(garden, socket.assigns.current_user)
     )
     |> assign(:garden, garden)}
  end

  defp render_species(species, common_name) do
    species_display_string(species, common_name)
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    common_names = Library.list_species_with_common_names() |> Enum.into(%{})
    seed = Gardens.get_seed!(id) |> Repo.preload(:harvest_species)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:common_name, common_names[seed.species])
     |> assign(:seed, seed)}
  end

  defp page_title(:show), do: "Show Plantable"
  defp page_title(:edit), do: "Edit Plantable"
end
