defmodule VisualGardenWeb.LibrarySeedLive.Index do
  use VisualGardenWeb, :live_view

  alias VisualGarden.Library
  alias VisualGarden.Library.LibrarySeed

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :library_seeds, Library.list_library_seeds())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Library seed")
    |> assign(:library_seed, Library.get_library_seed!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Library seed")
    |> assign(:library_seed, %LibrarySeed{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Library seeds")
    |> assign(:library_seed, nil)
  end

  @impl true
  def handle_info({VisualGardenWeb.LibrarySeedLive.FormComponent, {:saved, library_seed}}, socket) do
    {:noreply, stream_insert(socket, :library_seeds, library_seed)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    library_seed = Library.get_library_seed!(id)
    {:ok, _} = Library.delete_library_seed(library_seed)

    {:noreply, stream_delete(socket, :library_seeds, library_seed)}
  end
end
