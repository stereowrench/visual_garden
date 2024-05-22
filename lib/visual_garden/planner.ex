defmodule VisualGarden.Planner do
  import Ecto.Query, warn: false
  alias VisualGarden.Gardens.PlannerEntry
  alias VisualGarden.Library.Schedule
  alias VisualGarden.Library
  alias VisualGarden.Gardens
  alias VisualGarden.Repo

  def create_planner_entry(attrs \\ %{}) do
    # TODO we need to make sure the entry will still fit if there's a competing change.
    %PlannerEntry{}
    |> PlannerEntry.changeset(attrs)
    |> Repo.insert()
  end

  def change_planner_entry(%PlannerEntry{} = entry, attrs \\ %{}) do
    entry
    |> PlannerEntry.changeset(attrs)
  end

  def delete_planner_entry(%PlannerEntry{} = planner) do
    Repo.delete(planner)
  end

  def get_planner_entry!(id) do
    Repo.get!(PlannerEntry, id)
  end

  def get_end_date(square, bed, start_date) do
    start_date =
      if start_date do
        start_date
      else
        Date.utc_today()
      end

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
        |> Enum.sort(Date)
        |> Enum.take(1)
        |> hd()
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
      if bed.width > bed.length do
        x = rem(z, bed.width)
        # => j
        y = trunc(:math.floor(z / bed.width))
        {y, x}
      else
        x = rem(z, bed.length)
        # => j
        y = trunc(:math.floor(z / bed.length))
        {y, x}
      end
    else
      _ -> :error
    end
  end

  def schedules_map(species) do
    # TODO dirty hack
    schedule_ids =
      species
      |> Enum.map(fn {sp, _, _} -> sp end)
      |> Repo.preload([:schedules])
      |> Enum.flat_map(fn sp -> Enum.map(sp.schedules, & &1.id) end)

    Repo.all(from s in Schedule, where: s.id in ^schedule_ids, preload: [:species])
    |> Enum.map(&{&1.id, &1})
    |> Enum.into(%{})
  end

  def get_plantables_from_garden(
        bed,
        start_date,
        end_date \\ nil,
        today \\ nil,
        species \\ nil,
        schedules_map \\ nil,
        seeds \\ nil,
        garden \\ nil
      ) do
    # get seeds in garden from bed.garden_id
    # get species -> schedule map
    # get days of maturation for each seed
    seeds = if seeds, do: seeds, else: Gardens.list_seeds(bed.garden_id)
    garden = if garden, do: garden, else: Gardens.get_garden!(bed.garden_id)
    region_id = garden.region_id
    tz = garden.tz

    species = if species, do: species, else: Library.list_species_with_schedule(region_id)

    schedules_map =
      if schedules_map do
        schedules_map
      else
        schedules_map(species)
      end

    get_plantables(seeds, region_id, tz, start_date, end_date, today, species, schedules_map)
  end

  # def get_plantables_from_garden_ignore_schedule(bed, start_date, end_date \\ nil, today \\ nil) do
  #   seeds = Gardens.list_seeds(bed.garden_id)
  #   garden = Gardens.get_garden!(bed.garden_id)
  #   region_id = garden.region_id
  #   tz = garden.tz

  #   today =
  #     if today do
  #       today
  #     else
  #       Timex.now(tz) |> DateTime.to_date()
  #     end

  #   start_date =
  #     if Timex.before?(start_date, today) do
  #       today
  #     else
  #       start_date
  #     end

  #   for seed <- seeds do
  #     nursery =
  #       if schedule.nursery_lead_weeks_max && schedule.nursery_lead_weeks_min &&
  #            seed.type == :seed do
  #       else
  #         %{}
  #       end

  #     non_nursery = %{
  #       type: seed.type,
  #       sow_start: sow_start,
  #       sow_end: sow_end,
  #       days: days,
  #       seed: seed,
  #       species: species,
  #     }

  #     [nursery, non_nursery]
  #   end
  #   |> List.flatten()
  # end

  defp get_plantables(seeds, _region_id, tz, start_date, end_date, today, species, schedules_map) do
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

    schedules_map =
      schedules_map
      |> Enum.group_by(fn {_schedule_id, schedule} ->
        schedule.species_id
      end)
      |> Enum.map(fn {spid, schedules} ->
        {spid, Enum.map(schedules, fn {_, sched} -> sched end)}
      end)
      |> Enum.into(%{})

    species_map =
      species
      |> Enum.map(fn {sp, _common_name, _} -> sp end)
      |> Enum.group_by(& &1.id)
      |> Enum.map(fn {a, b} -> {a, Enum.uniq(b)} end)
      |> Enum.into(%{})

    species_name_map =
      species
      |> Enum.map(fn {sp, common_name, _} -> {sp.id, common_name} end)
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

            sow_start = clamp_date(start_date, end_date, sow_start)
            sow_end = clamp_date(start_date, end_date, sow_end)

            %{
              type: seed.type,
              sow_start: sow_start,
              sow_end: sow_end,
              days: days,
              seed: seed,
              species: species,
              schedule: schedule,
              common_name: species_name_map[seed.species_id]
            }
          end

        if schedule.nursery_lead_weeks_max && schedule.nursery_lead_weeks_min &&
             seed.type == :seed do
          clamped_start = clamp_date(start_date, end_date, sched_start)
          clamped_end = clamp_date(start_date, end_date, sched_end)

          if Timex.diff(clamped_end, clamped_start, :days) < 14 do
            [direct]
          else
            # the latest nursery date is sow_end - days to maturation, clamped to start/end
            # the first nursery date is sow_start - 7 * lead_weeks_max, clamped to start/end
            # sow_end doesn't change
            # sow_start becomes clamped nursery start + 7 * lead_weeks_min, clamped to start/end
            sow_start = Timex.shift(a, days: -days)
            sow_end = Timex.shift(b, days: -days)

            nursery_end =
              clamp_date(start_date, end_date, Timex.shift(sow_end, days: -days))

            nursery_start =
              clamp_date(
                start_date,
                end_date,
                Timex.shift(sow_start, weeks: -schedule.nursery_lead_weeks_max)
              )

            sow_start =
              clamp_date(
                start_date,
                end_date,
                Timex.shift(nursery_start, weeks: schedule.nursery_lead_weeks_min)
              )

            if Timex.diff(nursery_end, nursery_start, :days) < 1 do
              [direct]
            else
              nursery = %{
                type: "nursery",
                nursery_start: nursery_start,
                nursery_end: nursery_end,
                min_lead: schedule.nursery_lead_weeks_min,
                max_lead: schedule.nursery_lead_weeks_max,
                sow_start: sow_start,
                sow_end: sow_end,
                days: days,
                seed: seed,
                species: species,
                schedule: schedule,
                common_name: species_name_map[seed.species_id]
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

    Repo.all(from pe in PlannerEntry, where: pe.bed_id in ^bed_ids, preload: [:nursery_entry])
    |> Enum.group_by(& &1.bed_id)
  end

  # TODO scope to user's gardens
  def get_todo_items() do
    gardens = Gardens.list_gardens()
    today = Date.utc_today()

    for garden <- gardens do
      entries =
        list_planner_entries(garden.id)
        |> Repo.preload([:nursery_entry])

      nursery_filter_fn = fn entry ->
        entry.nursery_start != nil and entry.nursery_end != nil and entry.nursery_entry != nil
      end

      nursery_entries =
        entries
        |> Enum.filter(nursery_filter_fn)

      # nursery entries that end after today

      current_n_fn = fn entry ->
        Timex.diff(today, entry.nursery_end, :days) <= 0
      end

      current_nursery_entries =
        nursery_entries
        |> Enum.filter(current_n_fn)

      overdue_nursery_entries =
        nursery_entries
        |> Enum.reject(current_n_fn)

      # nursery entires that end before today

      planting_entries =
        entries
        |> Enum.reject(nursery_filter_fn)

      # to_plant =
      #   entries
      #   |> Enum.map()

      # TODO to plant:
      # If
    end
  end
end
