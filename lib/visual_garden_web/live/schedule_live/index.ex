defmodule VisualGardenWeb.ScheduleLive.Index do
  use VisualGardenWeb, :live_view

  alias VisualGarden.Library
  alias VisualGarden.Library.Schedule

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:can_modify?, Authorization.can_modify_library?(socket.assigns.current_user))
     |> stream(:schedules, Library.list_schedules())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Schedule")
    |> assign(:schedule, Library.get_schedule!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Schedule")
    |> assign(:schedule, %Schedule{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Schedules")
    |> assign(:schedule, nil)
  end

  @impl true
  def handle_info({VisualGardenWeb.ScheduleLive.FormComponent, {:saved, schedule}}, socket) do
    {:noreply, stream_insert(socket, :schedules, Library.get_schedule!(schedule.id))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    schedule = Library.get_schedule!(id)
    {:ok, _} = Library.delete_schedule(schedule)

    {:noreply, stream_delete(socket, :schedules, schedule)}
  end
end
