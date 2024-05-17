defmodule VisualGardenWeb.PlannerLive.GraphComponent do
  use VisualGardenWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <svg
      viewBox={"0 0 600 #{30 + 25 * (@bed.width * @bed.length)}"}
      xmlns="http://www.w3.org/2000/svg"
    >
      <%= for mo <- generate_months(@garden.tz, @extent_dates) do %>
        <rect
          width={mo.days_in_month}
          height="25"
          x={40 + x_shift(mo.mo_num, @garden.tz, @extent_dates)}
          style="stroke-width:0.5;stroke:black"
          fill="none"
        >
        </rect>
        <text
          y="13"
          x={40 + x_shift(mo.mo_num, @garden.tz, @extent_dates) + 3}
          style="font-size:11px;"
        >
          <%= mo.month_name %>
        </text>
      <% end %>
      <%= for i <- 0..(@bed.length - 1) do %>
        <%= for j <- 0..(@bed.width - 1) do %>
          <text y={13 + 25 + 25 * (i * @bed.width + j)} x="0" style="font-size:11px;">
            Sq <%= i %>, <%= j %>
          </text>
        <% end %>
      <% end %>

      <%= for {group, spans} <- generate_available_regions(@planner_entries, @extent_dates, @bed) do %>
        <%= for %{start_date: a, finish_date: b} <- spans do %>
          <.link patch={
            ~p"/planners/#{@garden.id}/#{@bed.id}/#{group}/new?#{[start_date: Date.to_string(a)]}"
          }>
            <%!-- <text
             y={25 + 25 * (group)}
            >
              <%= VisualGarden.Planner.parse_square(to_string(group), @bed) |> (fn {x, y} -> "#{x}, #{y}" end).() %>
            </text> --%>
            <rect
              width={Timex.diff(b, a, :days)}
              height="25"
              y={25 + 25 * (group)}
              class="new-crop-span"
              x={40 + x_shift_date(a, @garden.tz, @extent_dates)}
            >
            </rect>
          </.link>
        <% end %>
      <% end %>

      <%= for entry <- @planner_entries do %>
        <.link
          patch={~p"/planners/#{@garden.id}/#{@bed.id}/#{bed_square(entry, @bed)}/#{entry.id}/edit"}
          class="crop-span"
        >
          <rect
            width={Timex.diff(entry.end_plant_date, entry.start_plant_date, :days)}
            height="25"
            class="crop-span-end"
            y={25 + 25 * bed_square(entry, @bed)}
            x={40 + x_shift_date(entry.start_plant_date, @garden.tz, @extent_dates)}
          >
          </rect>
          <rect
            width={
              entry.days_to_maturity - Timex.diff(entry.end_plant_date, entry.start_plant_date, :days)
            }
            height="25"
            y={25 + 25 * bed_square(entry, @bed)}
            x={
              40 +
                x_shift_date(
                  Timex.shift(entry.start_plant_date,
                    days: Timex.diff(entry.end_plant_date, entry.start_plant_date, :days)
                  ),
                  @garden.tz,
                  @extent_dates
                )
            }
          >
          </rect>
          <rect
            width={Timex.diff(entry.end_plant_date, entry.start_plant_date, :days)}
            height="25"
            y={25 + 25 * bed_square(entry, @bed)}
            class="crop-span-end"
            x={
              40 +
                x_shift_date(
                  Timex.shift(entry.start_plant_date, days: entry.days_to_maturity),
                  @garden.tz,
                  @extent_dates
                )
            }
          >
          </rect>
          <text
            dominant-baseline="central"
            text-anchor="middle"
            x={
              40 + x_shift_date(entry.start_plant_date, @garden.tz, @extent_dates) +
                entry.days_to_maturity / 2 +
                +Timex.diff(entry.end_plant_date, entry.start_plant_date, :days) / 2
            }
            y={25 + 25 * bed_square(entry, @bed) + 25 / 2}
            style="font-size: 11px"
          >
            <%= entry.common_name %>
          </text>

          <line
            x1={
              40 + x_shift_date(entry.end_plant_date, @garden.tz, @extent_dates) +
                entry.days_to_refuse
            }
            x2={
              40 + x_shift_date(entry.end_plant_date, @garden.tz, @extent_dates) +
                entry.days_to_refuse
            }
            y1={25 + 25 * bed_square(entry, @bed)}
            y2={2 * 25 + 25 * bed_square(entry, @bed)}
            stroke="red"
          />
        </.link>
      <% end %>

      <line
        x1={40 + x_shift_date(DateTime.utc_now(), nil, @extent_dates)}
        y1={0}
        x2={40 + x_shift_date(DateTime.utc_now(), nil, @extent_dates)}
        y2={13 + 25 * (@bed.length * @bed.width)}
        stroke="blue"
      />
    </svg>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def months_in_extent({start_d, end_d}) do
    Timex.diff(end_d, start_d, :months)
  end

  def generate_months(_tz, extent_dates) do
    days = {start_d, _} = extent_dates

    for mo <- 1..months_in_extent(days) do
      ed =
        start_d
        |> Timex.shift(months: mo - 1)

      days_in_month =
        ed |> Timex.days_in_month()

      month_name = Timex.month_shortname(ed.month)

      %{
        days_in_month: days_in_month,
        month_name: month_name,
        mo_num: mo
      }
    end
  end

  def x_shift(mo, _tz, extent_dates) do
    {start_d, _end_d} = extent_dates

    beg = start_d

    en =
      start_d
      |> Timex.shift(months: mo - 1)
      |> Timex.shift(days: -1)
      |> Timex.end_of_month()

    Timex.diff(en, beg, :days)
  end

  def x_shift_date(date, _tz, extent_dates) do
    {start_d, _} = extent_dates
    Timex.diff(date, start_d, :days)
  end

  def clamp_date(start, en, date) do
    case Timex.diff(date, start, :days) do
      b when b > 0 ->
        case Timex.diff(en, date) do
          c when c > 0 -> date
          _ -> en
        end

      _ ->
        start
    end
  end

  def bed_square(entry, bed) do
    if bed.width > bed.length do
      entry.row * bed.width + entry.column
    else
      entry.row * bed.length + entry.column
    end
  end

  defp generate_available_regions(entries, extent_dates, bed) do
    {sd, ed} = extent_dates

    grouped =
      entries
      |> Enum.group_by(&bed_square(&1, bed))

    grouped =
      Enum.map(0..(bed.width * bed.length - 1), fn
        square_num ->
          case grouped[square_num] do
            nil -> {square_num, []}
            _el -> {square_num, grouped[square_num]}
          end
      end)
      |> Enum.into(%{})

    for {group, es} <- grouped, into: %{} do
      es = Enum.sort_by(es, & &1.start_plant_date, Date)
      plant_dates = Enum.map(es, & &1.start_plant_date)
      end_dates = Enum.map(es, & &1.end_plant_date)
      # TODO fix this
      days = Enum.map(es, & &1.days_to_refuse)

      pairs =
        for {pdate, {edate, days}} <- Enum.zip(plant_dates, Enum.zip(end_dates, days)),
            do: [pdate, Timex.shift(edate, days: days)]

      pairs = List.flatten(pairs)

      new_list =
        [Date.new!(DateTime.utc_now().year, 1, 1)] ++
          pairs ++ [Timex.shift(DateTime.utc_now(), years: 2)]

      chunks = Enum.chunk_every(new_list, 2)

      spans =
        for [a, b] <- chunks do
          %{
            start_date: clamp_date(DateTime.utc_now(), ed, a),
            finish_date: clamp_date(sd, ed, b)
          }
        end
        |> Enum.filter(fn
          %{start_date: sd, finish_date: ed} ->
            Timex.diff(ed, sd, :days) > 0
        end)

      {group, spans}
    end
  end
end
