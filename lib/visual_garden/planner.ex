defmodule VisualGarden.Planner do
  import Ecto.Query, warn: false
  alias VisualGardenWeb.DisplayHelpers
  alias VisualGarden.Gardens.NurseryEntry
  alias VisualGarden.MyDateTime
  alias VisualGarden.Gardens.PlannerEntry
  alias VisualGarden.Library.Schedule
  alias VisualGarden.Library
  alias VisualGarden.Gardens
  alias VisualGarden.Repo

  def create_planner_entry(attrs \\ %{}, garden) do
    # TODO we need to make sure the entry will still fit if there's a competing change.
    %PlannerEntry{}
    |> PlannerEntry.changeset(attrs, garden)
    |> Repo.insert()
  end

  def set_planner_entry_plant(entry, plant_id, garden) do
    entry
    |> PlannerEntry.changeset(
      %{
        "plant_id" => plant_id,
        "start_plant_date" => MyDateTime.utc_today(),
        "end_plant_date" => MyDateTime.utc_today()
      },
      garden
    )
    |> Repo.update()
  end

  def set_entry_nurse_date(entry, garden) do
    date = MyDateTime.utc_today()

    entry
    |> PlannerEntry.changeset(
      %{
        nursery_start: date,
        nursery_end: date,
        start_plant_date:
          clamp_date(
            entry.start_plant_date,
            entry.end_plant_date,
            Timex.shift(date, weeks: entry.min_lead)
          ),
        end_plant_date:
          clamp_date(
            entry.start_plant_date,
            entry.end_plant_date,
            Timex.shift(date, weeks: entry.max_lead)
          )
      },
      garden
    )
  end

  def change_planner_entry(%PlannerEntry{} = entry, garden, attrs \\ %{}) do
    entry
    |> PlannerEntry.changeset(attrs, garden)
  end

  def update_planner_entry(%PlannerEntry{} = entry, garden, attrs \\ %{}) do
    entry
    |> PlannerEntry.changeset(attrs, garden)
    |> Repo.update()
  end

  def delete_planner_entry(%PlannerEntry{} = planner) do
    Repo.delete(planner)
  end

  def get_planner_entry!(id) do
    Repo.get!(PlannerEntry, id)
    |> Repo.preload([:nursery_entry, :bed, :seed])
  end

  def get_planner_entry_by_plant(plant_id) do
    Repo.one(from p in PlannerEntry, where: p.plant_id == ^plant_id)
  end

  def get_end_date(square, bed, start_date, skip_id \\ nil) do
    start_date =
      if start_date do
        start_date
      else
        VisualGarden.MyDateTime.utc_today()
      end

    {row, column} = parse_square(to_string(square), bed)

    mapped =
      Repo.all(
        from pe in PlannerEntry,
          where: pe.row == ^row and pe.column == ^column and pe.bed_id == ^bed.id
      )
      |> Enum.reject(fn pe ->
        pe.id == skip_id
      end)
      |> Enum.map(fn
        %{start_plant_date: spd, end_plant_date: epd, days_to_refuse: dtr} ->
          if Timex.between?(start_date, spd, Timex.shift(epd, days: dtr)) do
            []
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
      x = rem(z, bed.width)
      # => j
      y = trunc(:math.floor(z / bed.width))
      {x, y}
    else
      _ -> :error
    end
  end

  def schedules_map(region_id) do
    Repo.all(from s in Schedule, where: s.region_id == ^region_id, preload: [:species])
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
        garden \\ nil,
        species_names \\ nil
      ) do
    # get seeds in garden from bed.garden_id
    # get species -> schedule map
    # get days of maturation for each seed
    seeds = if seeds, do: seeds, else: Gardens.list_seeds(bed.garden_id)
    garden = if garden, do: garden, else: Gardens.get_garden!(bed.garden_id)
    region_id = garden.region_id
    tz = garden.tz

    species = if species, do: species, else: Library.list_species()

    species_names =
      if species_names, do: species_names, else: Library.list_species_with_common_names()

    schedules_map =
      if schedules_map do
        schedules_map
      else
        schedules_map(region_id)
      end

    get_plantables(
      seeds,
      region_id,
      tz,
      start_date,
      end_date,
      today,
      species,
      schedules_map,
      species_names
    )
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

  defp map_species_to_schedules(schedules_map, species) do
    collected =
      species
      |> Enum.group_by(fn s -> {s.id, {s.genus, s.name, s.variant, s.season, s.cultivar}} end)
      |> Enum.map(fn {{id, key}, _group} -> {key, schedules_map[id]} end)
      |> Enum.into(%{})

    for specy <- species do
      species_bubble(collected, specy)
    end
    |> Enum.reject(&is_nil/1)
    |> Enum.into(%{})
  end

  def get_available_species(region_id) do
    schedules_map = schedules_map(region_id)
    species = Library.list_species()
    map = do_map_to_species(schedules_map, species)

    Library.list_species_with_common_names()
    |> Enum.filter(fn {species, _name} -> map[species.id] end)
    |> Enum.map(fn {species, name} ->
      %{
        label: DisplayHelpers.species_display_string_simple(species, name),
        matches: [],
        value: to_string(species.id)
      }
    end)
  end

  def get_available_species() do
    Library.list_species_with_common_names()
    |> Enum.map(fn {species, name} ->
      %{
        label: DisplayHelpers.species_display_string_simple(species, name),
        matches: [],
        value: to_string(species.id)
      }
    end)
  end

  def species_bubble(
        collected,
        species = %{
          genus: genus,
          name: name,
          variant: variant,
          cultivar: cultivar,
          season: season
        }
      ) do
    with nil <- collected[{genus, name, variant, season, cultivar}],
         nil <- collected[{genus, name, variant, season, nil}],
         nil <- collected[{genus, name, variant, nil, nil}],
         nil <- collected[{genus, name, nil, nil, nil}] do
      nil
    else
      map -> {species.id, map}
    end
  end

  def do_map_to_species(schedules_map, species) do
    schedules_map
    |> Enum.group_by(fn {_schedule_id, schedule} ->
      schedule.species_id
    end)
    |> Enum.map(fn {spid, schedules} ->
      {spid, Enum.map(schedules, fn {_, sched} -> sched end)}
    end)
    |> Enum.into(%{})
    |> map_species_to_schedules(species)
  end

  defp get_plantables(
         seeds,
         _region_id,
         tz,
         start_date,
         end_date,
         today,
         species,
         schedules_map,
         species_names
       ) do
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
      do_map_to_species(schedules_map, species)

    species_map =
      species
      |> Enum.group_by(& &1.id)
      |> Enum.map(fn {a, b} -> {a, Enum.uniq(b)} end)
      |> Enum.into(%{})

    species_name_map =
      species_names
      |> Enum.map(fn {sp, common_name} -> {sp.id, common_name} end)
      |> Enum.into(%{})

    for seed <- seeds do
      species = species_map[seed.species_id]

      for schedule <- schedules_map[seed.species_id] || [] do
        if to_string(seed.type) in (schedule.plantable_types || []) do
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
                clamp_date(
                  start_date,
                  end_date,
                  Timex.shift(sow_end, weeks: -schedule.nursery_lead_weeks_min)
                )

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
        else
          []
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

    if Timex.before?(today, endd) && Timex.after?(start, endd) do
      {Timex.shift(start, years: -1), endd}
    else
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
  end

  def list_planner_entries_ungrouped(garden_id) do
    beds = Gardens.list_beds(garden_id)
    bed_ids = beds |> Enum.map(& &1.id)

    Repo.all(
      from pe in PlannerEntry,
        where: pe.bed_id in ^bed_ids,
        preload: [:nursery_entry, :seed, :bed]
    )
  end

  def list_planner_entries(garden_id) do
    list_planner_entries_ungrouped(garden_id)
    |> Enum.group_by(& &1.bed_id)
  end

  def list_planner_entries_for_user(user) do
    gardens = Gardens.list_gardens(user)

    for garden <- gardens do
      list_planner_entries_ungrouped(garden.id)
    end
    |> List.flatten()
  end

  def get_orphaned_plants(garden) do
    Repo.all(
      from ne in NurseryEntry,
        where: is_nil(ne.planner_entry_id) and ne.garden_id == ^garden.id,
        preload: [:seed]
    )
  end

  def get_todo_items(user) do
    gardens = Gardens.list_gardens(user)
    today = VisualGarden.MyDateTime.utc_today()

    for garden <- gardens do
      entries =
        list_planner_entries_ungrouped(garden.id)
        |> Repo.preload([:nursery_entry, :plant])

      nursery_filter_fn = fn entry ->
        entry.nursery_start != nil and entry.nursery_end != nil and entry.nursery_entry == nil
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
        |> Enum.map(fn ne ->
          today = MyDateTime.utc_today()

          date =
            if Timex.after?(ne.nursery_start, today) do
              ne.nursery_start
            else
              today
            end

          %{
            type: "nursery_plant",
            planner_entry_id: ne.id,
            date: date,
            end_date: ne.nursery_end,
            garden_id: garden.id
          }
        end)

      overdue_nursery_entries =
        nursery_entries
        |> Enum.reject(current_n_fn)
        |> Enum.map(fn ne ->
          %{
            type: "nursery_overdue",
            date: ne.nursery_end,
            planner_entry_id: ne.id,
            garden_id: garden.id
          }
        end)

      current_p_fn = fn entry ->
        Timex.diff(today, entry.end_plant_date, :days) <= 0
      end

      planting_entries =
        entries
        |> Enum.reject(nursery_filter_fn)
        |> Enum.reject(&(&1.plant_id != nil))

      refuse_entries =
        entries
        |> Enum.filter(&(&1.plant_id != nil))
        |> Enum.map(fn a ->
          %{
            type: "refuse",
            planner_entry_id: a.id,
            plant: a.plant,
            bed: a.bed,
            date: Timex.shift(a.end_plant_date, days: a.days_to_refuse),
            garden_id: garden.id
          }
        end)

      current_plant_entries =
        planting_entries
        |> Enum.filter(current_p_fn)
        |> Enum.map(fn entry ->
          today = MyDateTime.utc_today()

          date =
            if Timex.after?(entry.start_plant_date, today) do
              entry.start_plant_date
            else
              today
            end

          %{
            type: "plant",
            planner_entry_id: entry.id,
            date: date,
            end_date: entry.end_plant_date,
            garden_id: garden.id
          }
        end)

      overdue_plant_entries =
        planting_entries
        |> Enum.reject(current_p_fn)
        |> Enum.map(fn entry ->
          %{
            type: "plant_overdue",
            date: entry.end_plant_date,
            planner_entry_id: entry.id,
            garden_id: garden.id
          }
        end)

      orphaned_plants =
        get_orphaned_plants(garden)
        |> Enum.map(fn ne ->
          %{
            type: "orphaned_nursery",
            date: MyDateTime.utc_today(),
            nursery_entry_id: ne.id,
            name: ne.seed.name,
            garden_id: garden.id
          }
        end)

      water_entries =
        for bed <- Gardens.list_beds(garden.id) do
          bed_last = Gardens.get_last_water_for_bed(bed.id)

          if bed_last do
            last_water = bed_last.event_time

            if Timex.before?(Timex.shift(last_water, hours: 18), MyDateTime.utc_now()) do
              [
                %{
                  type: "water",
                  date: MyDateTime.utc_today(),
                  bed: bed,
                  garden_id: garden.id,
                  last_water: last_water
                }
              ]
            else
              []
            end
          else
            [
              %{
                type: "water",
                date: MyDateTime.utc_today(),
                bed: bed,
                garden_id: garden.id,
                last_water: nil
              }
            ]
          end
        end
        |> List.flatten()

      media_entries =
        for bed <- Gardens.list_beds(garden.id) do
          bed_last = Gardens.get_last_media_for_bed(bed.id)

          if bed_last do
            []
          else
            %{
              type: "media",
              date: MyDateTime.utc_today(),
              bed: bed,
              garden_id: garden.id
            }
          end
        end
        |> List.flatten()

      refuse_entries ++
        media_entries ++
        water_entries ++
        orphaned_plants ++
        current_nursery_entries ++
        overdue_nursery_entries ++ current_plant_entries ++ overdue_plant_entries
    end
    |> List.flatten()
  end

  def create_planner_entry_for_orphaned_nursery(nursery, garden, row, column, bed_id, refuse_date) do
    nursery = Repo.preload(nursery, [:seed])
    days_to_refuse = Timex.diff(refuse_date, MyDateTime.utc_today(), :days)

    {_, common_name} =
      Library.list_species_with_common_names()
      |> Enum.find(fn {a, _name} -> a.id == nursery.seed.species_id end)

    create_planner_entry(
      %{
        nursery_start: nursery.sow_date,
        nursery_end: nursery.sow_date,
        days_to_maturity: nursery.seed.days_to_maturation,
        start_plant_date: MyDateTime.utc_today(),
        end_plant_date: MyDateTime.utc_today(),
        common_name: common_name,
        days_to_refuse: days_to_refuse,
        row: row,
        column: column,
        bed_id: bed_id,
        seed_id: nursery.seed_id
      },
      garden
    )
  end

  def get_open_slots(garden, date) do
    for bed <- Gardens.list_beds(garden.id) do
      for square <- 0..(bed.width * bed.length) do
        end_date = get_end_date(square, bed, MyDateTime.utc_today())

        case end_date do
          :error ->
            []

          nil ->
            {r, c} = parse_square(to_string(square), bed)

            %{
              bed_id: bed.id,
              bed_name: bed.name,
              row: r,
              col: c,
              end_date: end_date
            }

          _ ->
            if Timex.before?(end_date, date) do
              []
            else
              {r, c} = parse_square(to_string(square), bed)

              %{
                bed_id: bed.id,
                bed_name: bed.name,
                row: r,
                col: c,
                end_date: end_date
              }
            end
        end
      end
    end
    |> List.flatten()
  end
end
