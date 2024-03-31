defmodule VisualGardenWeb.EventLogLive.Index do
  use VisualGardenWeb, :live_view

  alias VisualGarden.Gardens
  alias VisualGarden.Gardens.EventLog

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :event_logs, Gardens.list_event_logs())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Event log")
    |> assign(:event_log, Gardens.get_event_log!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Event log")
    |> assign(:event_log, %EventLog{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Event logs")
    |> assign(:event_log, nil)
  end

  @impl true
  def handle_info({VisualGardenWeb.EventLogLive.FormComponent, {:saved, event_log}}, socket) do
    {:noreply, stream_insert(socket, :event_logs, event_log)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    event_log = Gardens.get_event_log!(id)
    {:ok, _} = Gardens.delete_event_log(event_log)

    {:noreply, stream_delete(socket, :event_logs, event_log)}
  end
end
