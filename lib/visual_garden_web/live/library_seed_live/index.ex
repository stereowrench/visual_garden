defmodule VisualGardenWeb.LibrarySeedLive.Index do
  alias VisualGarden.Repo
  alias VisualGarden.Gardens
  use VisualGardenWeb, :live_view

  alias VisualGarden.Library
  alias VisualGarden.Library.LibrarySeed

  @impl true
  def mount(%{"id" => seed_id, "garden_id" => garden_id} = params, _session, socket) do
    Authorization.authorize_garden_modify(garden_id, socket.assigns.current_user)

    {:ok,
     socket
     |> assign(:gardens, Gardens.list_gardens(socket.assigns.current_user))
     |> assign(:garden, Gardens.get_garden!(garden_id))
     |> assign(:library_seed, Library.get_library_seed!(seed_id))}
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:gardens, Gardens.list_gardens(socket.assigns.current_user))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> assign(:species, params["species"])
     |> stream(:library_seeds, Library.list_library_seeds() |> filter_species(params))
     |> assign(:can_edit?, Authorization.can_modify_library?(socket.assigns.current_user))
     |> apply_action(socket.assigns.live_action, params)}
  end

  def filter_species(seeds, %{"species" => sp}) do
    seeds = Repo.preload(seeds, [:species])
    cs = Library.list_species_with_common_names() |> Enum.into(%{})

    seeds
    |> Enum.filter(fn seed ->
      cs[seed.species] == sp
    end)
  end

  def filter_species(seeds, _) do
    seeds
  end

  defp apply_action(socket, action, params = %{"id" => id})
       when action in [:copy, :copy_garden] do
    lseed = Library.get_library_seed!(id)

    if Gardens.get_seed_by_library_seed(lseed.id, socket.assigns.garden.id) do
      if params["ret"] == "seed" do
        socket
        |> put_notification(Normal.new(:warning, "Seed already in garden"))
        |> push_patch(
          to:
            if action == :copy_garden do
              ~p"/gardens/#{socket.assigns.garden.id}/library_seeds/#{lseed.id}?#{if params["species"], do: [species: params["species"]], else: []}"
            else
              ~p"/library_seeds/#{lseed.id}?#{if params["species"], do: [species: params["species"]], else: []}"
            end
        )
      else
        socket
        |> put_notification(Normal.new(:warning, "Seed already in garden"))
        |> push_patch(
          to:
            if action == :copy_garden do
              ~p"/gardens/#{socket.assigns.garden.id}/library_seeds"
            else
              ~p"/library_seeds"
            end
        )
      end
    else
      {:ok, _} =
        Gardens.create_seed(%{
          garden_id: socket.assigns.garden.id,
          name: "#{lseed.name} - #{lseed.species.name} - #{lseed.manufacturer}",
          description: "A seed from #{lseed.manufacturer}",
          days_to_maturation: lseed.days_to_maturation,
          species_id: lseed.species_id,
          type: lseed.type,
          library_seed_id: lseed.id
        })

      if params["ret"] == "seed" do
        socket
        |> put_notification(Normal.new(:success, "Added seed to garden!"))
        |> push_patch(
          to:
            if action == :copy_garden do
              ~p"/gardens/#{socket.assigns.garden.id}/library_seeds/#{lseed.id}?#{if socket.assigns.species, do: [species: socket.assigns.species], else: []}"
            else
              ~p"/library_seeds/#{lseed.id}?#{if socket.assigns.species, do: [species: socket.assigns.species], else: []}"
            end
        )
      else
        socket
        |> put_notification(Normal.new(:success, "Added seed to garden!"))
        |> push_patch(
          to:
            if action == :copy_garden do
              ~p"/gardens/#{socket.assigns.garden.id}/library_seeds?#{if socket.assigns.species, do: [species: socket.assigns.species], else: []}"
            else
              ~p"/library_seeds?#{if socket.assigns.species, do: [species: socket.assigns.species], else: []}"
            end
        )
      end
    end
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Library Plantable")
    |> assign(:library_seed, Library.get_library_seed!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Library Plantable")
    |> assign(:library_seed, %LibrarySeed{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Library Plantables")
    |> assign(:library_seed, nil)
  end

  defp apply_action(socket, :garden_library, %{"garden_id" => garden_id}) do
    garden = Gardens.get_garden!(garden_id)

    socket
    |> assign(:garden, garden)
    |> assign(:page_title, "Listing Library Plantables")
    |> assign(:library_seed, nil)
  end

  @impl true
  def handle_info({VisualGardenWeb.LibrarySeedLive.FormComponent, {:saved, library_seed}}, socket) do
    {:noreply, stream_insert(socket, :library_seeds, library_seed)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    Authorization.authorize_library(socket.assigns.current_user)
    library_seed = Library.get_library_seed!(id)
    {:ok, _} = Library.delete_library_seed(library_seed)

    {:noreply, stream_delete(socket, :library_seeds, library_seed)}
  end
end
