defmodule VisualGardenWeb.EventLogLive.Show do
  use VisualGardenWeb, :live_view

  alias VisualGarden.Gardens

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:event_log, Gardens.get_event_log!(id))}
  end

  defp page_title(:show), do: "Show Event log"
  defp page_title(:edit), do: "Edit Event log"

  def render_events(assigns) do
    ~H"""
    <div class="flow-root">
      <ul role="list" class="-mb-8" id="event-log-list" phx-update="stream">
        <%= for {_name, event} <- @events do %>
          <li title="Event type" id={"event_log_#{event.id}"}>
            <div class="relative pb-8">
              <span class="absolute left-4 top-4 -ml-px h-full w-0.5 bg-gray-200" aria-hidden="true">
              </span>
            </div>
            <div class="flex min-w-0 flex-1 justify-between space-x-4 pt-1.5">
              <div>
                <p class="text-sm text-gray-500">
                  <%= event.event_type %>
                </p>
              </div>
              <div class="whitespace-nowrap text-right text-sm text-gray-500">
                <time datetime="2020-09-20">Sep 20</time>
              </div>
            </div>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end
end
