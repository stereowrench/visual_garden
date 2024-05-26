defmodule VisualGardenWeb.SeedLive.Index do
  alias VisualGarden.Authorization.UnauthorizedError
  use VisualGardenWeb, :live_view

  alias VisualGarden.Gardens
  alias VisualGarden.Gardens.Seed

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
     |> stream(:seeds, Gardens.list_seeds(garden_id))
     |> assign(:garden, garden)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Seed")
    |> assign(:seed, Gardens.get_seed!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Seed")
    |> assign(:seed, %Seed{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Seeds")
    |> assign(:seed, nil)
  end

  @impl true
  def handle_info({VisualGardenWeb.SeedLive.FormComponent, {:saved, seed}}, socket) do
    {:noreply, stream_insert(socket, :seeds, seed)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    Authorization.authorize_garden_modify(socket.assigns.garden.id, socket.assigns.current_user)
    seed = Gardens.get_seed!(id)

    unless seed.garden_id == socket.assigns.garden.id do
      raise UnauthorizedError
    end

    {:ok, _} = Gardens.delete_seed(seed)

    {:noreply, stream_delete(socket, :seeds, seed)}
  end
end
