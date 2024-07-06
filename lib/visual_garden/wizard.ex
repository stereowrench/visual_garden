defmodule VisualGarden.Wizard do
  alias VisualGarden.Authorization.UnauthorizedError
  alias VisualGarden.Wizard.WizardGarden
  alias VisualGarden.Wizard.TempUser
  alias VisualGarden.MyDateTime
  import Ecto.Query, warn: false
  alias VisualGarden.Repo

  def get_temp_user(id) do
    Repo.get(TempUser, id)
  end

  def create_temp_user!() do
    %TempUser{}
    |> TempUser.changeset(%{})
    |> Repo.insert!()
  end

  def delete_wizard_garden!(wg) do
    Repo.delete!(wg)
  end

  def get_wizard_garden!(id, {user, temp_user}) do
    g = Repo.get!(WizardGarden, id)

    if (user && user.id == g.user_id) || (temp_user && temp_user.id == g.temp_user_id) do
      g |> Repo.preload([:garden])
    else
      raise UnauthorizedError
    end
  end

  def create_wizard_garden_from_garden!(garden, {user, temp_user}) do
    attrs =
      if user do
        %{user_id: user.id}
      else
        %{temp_user_id: temp_user.id}
      end

    attrs = Map.merge(attrs, %{garden_id: garden.id, tz: garden.tz, region_id: garden.region_id})

    %WizardGarden{}
    |> WizardGarden.changeset(attrs)
    |> Repo.insert!()
    |> Repo.preload([:garden])
  end

  def list_wizard_gardens({nil, temp_user}) do
    Repo.all(from g in WizardGarden, where: g.temp_user_id == ^temp_user.id)
  end

  def list_wizard_gardens({user, nil}) do
    Repo.all(from g in WizardGarden, where: g.user_id == ^user.id)
  end

  def list_wizard_gardens({user, temp_user}) do
    Repo.all(
      from g in WizardGarden, where: g.user_id == ^user.id or g.temp_user_id == ^temp_user.id
    )
  end

  def convert_from_planner_to_optimizer(planner, rows, cols, filter_after_days \\ nil) do
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
      |> Enum.map(fn entry ->
        if filter_after_days do
          if entry.s > filter_after_days do
            nil
          else
            if entry.e > filter_after_days do
              %{entry | e: filter_after_days}
            else
              entry
            end
          end
        else
          entry
        end
      end)
      |> Enum.reject(&is_nil(&1))
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
