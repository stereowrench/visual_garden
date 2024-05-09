defmodule VisualGarden.Planner do
  import Ecto.Query, warn: false
  alias VisualGarden.Gardens.PlannerEntry
  alias VisualGarden.Library.Schedule
  alias VisualGarden.Library
  alias VisualGarden.Gardens
  alias VisualGarden.Repo

  def get_end_date(square, bed, start_date) do
    {row, column} = parse_square(square, bed)

    mapped =
      Repo.all(
        from pe in PlannerEntry,
          where: pe.row == ^row and pe.column == ^column and pe.bed_id == ^bed.id
      )
      |> Enum.map(fn
        %{start_plant_date: spd, end_plant_date: epd, days_to_refuse: dtr} ->
          if Timex.between?(start_date, spd, Timex.shift(epd, days: dtr)) do
            :error
          else
            if Timex.before?(Timex.shift(epd, days: dtr), start_date) do
              []
            else
              spd
            end
          end
      end)
      |> List.flatten()

    if mapped == [] do
      nil
    else
      if Enum.any?(mapped, &(&1 == :error)) do
        :error
      else
        mapped
        |> Enum.sort(DateTime)
        |> Enum.take(1)
      end
    end
  end

  def parse_square(square, bed) do
    with b when not is_nil(b) <- bed,
         _ when not is_nil(square) <- square do
      # i + bed.length * j
      # is length, j is width
      {z, ""} = Integer.parse(square)
      # => i
      x = rem(z, bed.length)
      # => j
      y = trunc(:math.floor(z / bed.length))
      {x, y}
    end
  end

  def get_plantables_from_garden(bed, start_date, end_date \\ nil, today \\ nil) do
    # get seeds in garden from bed.garden_id
    # get species -> schedule map
    # get days of maturation for each seed
    seeds = Gardens.list_seeds(bed.garden_id)
    garden = Gardens.get_garden!(bed.garden_id)
    region_id = garden.region_id
    tz = garden.tz
    get_plantables(seeds, region_id, tz, start_date, end_date, today)
  end

  defp get_plantables(seeds, region_id, tz, start_date, end_date, today) do
    today =
      if today do
        today
      else
        Timex.now(tz) |> DateTime.to_date()
      end

    start_date =
      if Timex.before?(start_date, today) do
        today
      else
        start_date
      end

    species = Library.list_species_with_schedule(region_id)

    schedule_ids = Enum.map(species, fn {_, id} -> id end)

    schedules_map =
      Repo.all(from s in Schedule, where: s.id in ^schedule_ids, preload: [:species])
      |> Enum.map(&{&1.id, &1})
      |> Enum.into(%{})

    schedules_map =
      species
      |> Enum.map(fn {species, schedule_id} ->
        {species.id, schedules_map[schedule_id]}
      end)
      |> Enum.group_by(fn {sp_id, _schedule_id} -> sp_id end)
      |> Enum.map(fn {sp_id, vals} ->
        {sp_id, Enum.map(vals, fn {_, schedule} -> schedule end)}
      end)
      |> Enum.into(%{})

    species_map =
      species
      |> Enum.map(fn {sp, _} -> sp end)
      |> Enum.group_by(& &1.id)
      |> Enum.map(fn {a, b} -> {a, Enum.uniq(b)} end)
      |> Enum.into(%{})

    for seed <- seeds do
      species = species_map[seed.species_id]

      for schedule <- schedules_map[seed.species_id] || [] do
        {sched_start, sched_end} =
          unwrwap_dates(
            schedule.start_month,
            schedule.start_day,
            schedule.end_month,
            schedule.end_day,
            today
          )

        days = seed.days_to_maturation

        a = Timex.shift(sched_start, days: days)
        b = Timex.shift(sched_end, days: days)
        a = clamp_date(start_date, end_date, a)
        b = clamp_date(start_date, end_date, b)

        direct =
          if Timex.diff(b, a, :days) < 14 do
            []
          else
            sow_start = Timex.shift(a, days: -days)
            sow_end = Timex.shift(b, days: -days)

            %{
              type: seed.type,
              sow_start: sow_start,
              sow_end: sow_end,
              days: days,
              seed: seed,
              species: species,
              schedule: schedule
            }
          end

        if schedule.nursery_lead_weeks_max && schedule.nursery_lead_weeks_min &&
             seed.type == :seed do
          clamped_start = clamp_date(start_date, end_date, sched_start)
          clamped_end = clamp_date(start_date, end_date, sched_end)

          if Timex.diff(clamped_end, clamped_start, :days) < 14 do
            [direct]
          else
            c = Timex.shift(clamped_start, weeks: -schedule.nursery_lead_weeks_max)
            d = Timex.shift(clamped_end, weeks: -schedule.nursery_lead_weeks_min)

            e = Timex.shift(c, days: days)
            j = Timex.shift(d, days: days)
            e = clamp_date(start_date, end_date, e)
            j = clamp_date(start_date, end_date, j)
            nursery_start = Timex.shift(e, days: -days)
            nursery_end = Timex.shift(j, days: -days)

            ss = Timex.shift(nursery_start, weeks: schedule.nursery_lead_weeks_min)
            sow_start = clamp_date(start_date, end_date, ss)

            se = Timex.shift(nursery_start, weeks: schedule.nursery_lead_weeks_max)
            sow_end = clamp_date(start_date, end_date, se)

            if Timex.diff(d, c, :days) < 14 do
              [direct]
            else
              nursery = %{
                type: "nursery",
                nursery_start: nursery_start,
                nursery_end: nursery_end,
                sow_start: sow_start,
                sow_end: sow_end,
                days: days,
                seed: seed,
                species: species,
                schedule: schedule
              }

              [direct, nursery]
            end
          end
        else
          [direct]
        end
      end
    end
    |> List.flatten()
  end

  def clamp_date(start, en, date) do
    if start == nil do
      if en == nil do
        date
      else
        case Timex.diff(en, date) do
          c when c > 0 -> date
          _ -> en
        end
      end
    end

    case Timex.diff(date, start, :days) do
      b when b > 0 ->
        if en == nil do
          date
        else
          case Timex.diff(en, date) do
            c when c > 0 -> date
            _ -> en
          end
        end

      _ ->
        start
    end
  end

  def unwrwap_dates(m1, d1, m2, d2, today) do
    start = Date.new!(today.year, m1, d1)
    endd = Date.new!(today.year, m2, d2)

    {s, e} =
      if Timex.before?(start, endd) do
        {start, endd}
      else
        {start, Timex.shift(endd, years: 1)}
      end

    if Timex.before?(e, today) do
      {Timex.shift(s, years: 1), Timex.shift(e, years: 1)}
    else
      {s, e}
    end
  end

  def list_planner_entries(garden_id) do
    beds = Gardens.list_beds(garden_id)
    bed_ids = beds |> Enum.map(& &1.id)

    Repo.all(from pe in PlannerEntry, where: pe.bed_id in ^bed_ids)
    |> Enum.group_by(& &1.bed_id)
  end
end
