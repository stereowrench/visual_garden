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
      <br />
      <h3>Events</h3>
      <br />
      <ul role="list" class="-mb-8" id="event-log-list" phx-update="stream">
        <%= for event <- Enum.sort_by(@events, & &1.event_time) do %>
          <li title="Event type" id={"event_log_#{event.id}"}>
            <div class="relative pb-8">
              <span class="absolute left-4 top-4 -ml-px h-full w-0.5 bg-gray-200" aria-hidden="true">
              </span>
              <div class="relative flex space-x-3">
                <div>
                  <span class="h-8 w-8 rounded-full bg-gray-400 flex items-center justify-center ring-8 ring-white">
                    <.icon name="hero-x-mark-solid" class="h-5 w-5 text-white" />
                  </span>
                </div>
                <div class="flex min-w-0 flex-1 justify-between space-x-4 pt-1.5">
                  <div>
                    <p class="text-sm text-gray-500">
                      [<%= event.event_type %>] <.render_event event={event} />
                    </p>
                  </div>
                  <div class="whitespace-nowrap text-right text-sm text-gray-500">
                    <time datetime={event.event_time}>
                      <%= Timex.format!(event.event_time, "{relative}", :relative) %>
                    </time>
                  </div>
                </div>
              </div>
            </div>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end

  def render_event(assigns = %{event: %{event_type: type}}) do
    do_render_event(type, assigns)
  end

  defp do_render_event(:till, assigns) do
    ~H"""
    Tilled
    """
  end

  defp do_render_event(:water, assigns) do
    ~H"""
    Watered
    """
  end

  defp do_render_event(:transfer, assigns) do
    ~H"""
    <%= @event.transferred_amount %> <%= to_string(@event.transfer_units) %> transferred from
    <.link
      class="underline"
      navigate={
        ~p"/gardens/#{@event.transferred_from.garden_id}/products/#{@event.transferred_from_id}"
      }
    >
     <%= @event.transferred_from.name %>
    </.link>
    """
  end

  defp do_render_event(:plant, assigns) do
    ~H"""
    Planted <%= @event.plant.qty %>
    <%= if @event.plant.seed != nil do %>
      <.link
        class="underline"
        navigate={~p"/gardens/#{@event.product.garden_id}/seeds/#{@event.plant.seed.id}"}
      >
        <%= @event.plant.seed.name %>
      </.link>
      as
    <% end %>
    <.link
      class="underline"
      navigate={
        ~p"/gardens/#{@event.product.garden_id}/beds/#{@event.product.id}/plants/#{@event.plant.id}"
      }
    >
      <%= @event.plant.name %>.
    </.link>
    """
  end

  defp do_render_event(nil, assigns) do
    ~H"""
    Error unknown event
    """
  end
end
