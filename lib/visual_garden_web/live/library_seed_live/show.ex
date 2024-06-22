defmodule VisualGardenWeb.LibrarySeedLive.Show do
  alias VisualGarden.Gardens
  use VisualGardenWeb, :live_view

  alias VisualGarden.Library

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _, socket) do
    lseed = Library.get_library_seed!(id)
    gardens = Gardens.list_gardens(socket.assigns.current_user)
    common_names = Library.list_species_with_common_names() |> Enum.into(%{})

    {:noreply,
     socket
     |> assign(:species, params["species"])
     |> assign(:can_edit?, Authorization.can_modify_library?(socket.assigns.current_user))
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:gardens, gardens)
     |> assign(:common_name, common_names[lseed.species])
     |> assign(:library_seed, lseed)}
  end

  defp render_species(species, common_name) do
    species_display_string(species, common_name)
  end

  defp page_title(:show), do: "Show Library seed"
  defp page_title(:edit), do: "Edit Library seed"
end
