defmodule VisualGardenWeb.RegionLive.Show do
  alias VisualGardenWeb.DisplayHelpers
  use VisualGardenWeb, :live_view

  alias VisualGarden.Library

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    schedules = schedules(id)

    {:noreply,
     socket
     |> assign(:can_modify?, Authorization.can_modify_library?(socket.assigns.current_user))
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:region, Library.get_region!(id))
     |> assign(:schedules, schedules)}
  end

  defp schedules(id) do
    Library.list_schedules(id)
    |> Enum.group_by(& &1.species)
    |> Enum.map(fn {sp, scheds} ->
      sched_list =
        scheds
        |> Enum.map(fn sched ->
          s = Date.new!(2024, sched.start_month, sched.start_day)
          e = Date.new!(2024, sched.end_month, sched.end_day)

          if Timex.before?(e, s) do
            {sched, [Date.new!(2024, 1, 1), e, s, Date.new!(2024, 12, 31)]}
          else
            {sched, [s, e]}
          end
        end)

      for sched <- sched_list do
        {sp, sched}
      end
    end)
    |> List.flatten()
  end

  def rect_for2(assigns = %{dates: [a, b]}) do
    assigns = assign(assigns, a: a)
    assigns = assign(assigns, b: b)

    ~H"""
    <rect
      y={@idx * 60}
      style="stroke-width:0.5;stroke:black"
      height="60"
      fill="rgba(1,1,1,0.2)"
      width={Timex.diff(@b, @a, :days) * 2}
      x={Timex.diff(@a, Date.new!(2024, 1, 1), :days) * 2}
    />
    """
  end

  def types_str(assigns) do
    ~H"""
    [<%= for type <- Enum.intersperse(@schedule.plantable_types, ", ") do %>
      <%= type %>
    <% end %>]
    """
  end

  def rect_for(assigns = %{dates: dates}) do
    pairs = Enum.chunk_every(dates, 2)

    assigns =
      assign(assigns, pairs: pairs)
      |> assign(types_str: types_str(%{schedule: assigns.schedule}))

    ~H"""
    <g>
      <%= for pair <- @pairs do %>
        <.rect_for2 dates={pair} idx={@idx} />
      <% end %>
      <text dominant-baseline="central" text-anchor="middle" x={365} y={30 + 60 * @idx}>
        <%= @types_str %> <%= DisplayHelpers.species_display_string_simple(@species) %>
      </text>
    </g>
    """
  end

  defp page_title(:show), do: "Show Region"
  defp page_title(:edit), do: "Edit Region"
end
