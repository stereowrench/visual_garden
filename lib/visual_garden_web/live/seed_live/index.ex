defmodule VisualGardenWeb.SeedLive.Index do
  use VisualGardenWeb, :live_view

  alias VisualGarden.Gardens
  alias VisualGarden.Gardens.Seed

  @impl true
  def mount(%{"garden_id" => garden_id}, _session, socket) do
    {:ok,
     socket
     |> stream(:seeds, Gardens.list_seeds(garden_id))
     |> assign(:garden, Gardens.get_garden!(garden_id))}
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
    seed = Gardens.get_seed!(id)
    {:ok, _} = Gardens.delete_seed(seed)

    {:noreply, stream_delete(socket, :seeds, seed)}
  end
end
