defmodule VisualGarden.Wizard do
  alias VisualGarden.MyDateTime

  def convert_from_planner_to_optimizer(planner, rows, cols) do
    mapped =
      planner
      |> Enum.map(fn x ->
        m =
          Map.take(x, [:place, :seed, :type, :nursery_start, :nursery_end, :sow_start, :sow_end])

        start_days =
          if m[:nursery_start] do
            Timex.diff(m[:nursery_start], MyDateTime.utc_today(), :days)
          else
            Timex.diff(m[:sow_start], MyDateTime.utc_today(), :days)
          end

        end_days =
          if m[:nursery_end] do
            Timex.diff(m[:nursery_end], MyDateTime.utc_today(), :days)
          else
            Timex.diff(m[:sow_end], MyDateTime.utc_today(), :days)
          end

        %{seed: m.seed.id, s: start_days, e: end_days, type: m.type, place: m.place}
      end)
      |> Enum.group_by(& &1.seed)
      |> Enum.map(fn {seed_id, list} ->
        per_seed =
          list
          |> Enum.group_by(& &1.type)
          |> Enum.map(fn {type, for_type} ->
            map = Enum.group_by(for_type, & &1.place)

            windows =
              for i <- 0..(rows - 1) do
                for j <- 0..(cols - 1) do
                  for st <- map[{i, j}] || [] do
                    {st.s, st.e}
                  end
                end
              end

            {type, windows}
          end)

        {seed_id, per_seed}
      end)

    type_map =
      mapped
      |> Enum.map(fn {seed_id, per_seed} ->
        types = Enum.map(per_seed, fn {type, _windows} -> type end)
        {seed_id, types}
      end)
      |> Enum.into(%{})

    windows =
      mapped
      |> Enum.map(fn {seed_id, per_seed} ->
        wins = Enum.map(per_seed, fn {_type, windows} -> windows end)
        {seed_id, wins}
      end)
      |> Enum.into(%{})

    {windows, type_map}
  end
end
