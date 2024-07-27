defmodule VisualGarden.Library do
  @moduledoc """
  The Library context.
  """

  import Ecto.Query, warn: false
  alias VisualGarden.Library.SpeciesSchedule
  alias VisualGarden.MyDateTime
  alias VisualGarden.Planner
  alias VisualGarden.Gardens.PlannerEntry
  alias VisualGarden.Library.Species
  alias VisualGarden.Repo

  def link_species_and_schedule(species_id, schedule_id) do
    %SpeciesSchedule{}
    |> SpeciesSchedule.changeset(%{species_id: species_id, schedule_id: schedule_id})
    |> Repo.insert()
  end

  @doc """
  Returns the list of species.

  ## Examples

      iex> list_species()
      [%Species{}, ...]

  """
  def list_species do
    Repo.all(Species)
  end

  def get_species_by_common_name(name) do
    Repo.one(from s in Species, where: s.common_name == ^name)
  end

  @common_name_cte """
  SELECT
  	species.id as species_id,
    first_value(SPECIES."common_name") OVER (
  		PARTITION BY
  			SPECIES."name",
  			GENUS,
        VARIANT,
        SEASON,
        CULTIVAR
  		ORDER BY
  			"name" DESC,
  			GENUS DESC,
  			VARIANT DESC,
  			CULTIVAR DESC,
        SEASON DESC
  	) AS n0,
    first_value(SPECIES."common_name") OVER (
  		PARTITION BY
  			SPECIES."name",
  			GENUS,
        VARIANT,
        SEASON
  		ORDER BY
  			"name" DESC,
  			GENUS DESC,
  			VARIANT DESC,
        SEASON DESC
  	) AS n1,
  	first_value(SPECIES."common_name") OVER (
  		PARTITION BY
  			SPECIES."name",
  			GENUS,
        VARIANT
  		ORDER BY
  			"name" DESC,
  			GENUS DESC,
  			VARIANT DESC,
  			CULTIVAR DESC,
        SEASON DESC
  	) AS n2,
  	first_value(SPECIES."common_name") OVER (
  		PARTITION BY
  			SPECIES."name",
  			GENUS
  		ORDER BY
  			"name" DESC,
  			GENUS DESC,
  			VARIANT DESC,
  			CULTIVAR DESC,
        SEASON DESC
  	) AS n3
  FROM
  	SPECIES
  """
  def list_species_with_common_names do
    Species
    |> with_cte("squery", as: fragment(@common_name_cte))
    |> join(:inner, [s], q in "squery", on: s.id == q.species_id)
    |> select([s, q], {s, coalesce(q.n0, q.n1) |> coalesce(q.n2) |> coalesce(q.n3)})
    |> Repo.all()
  end

  def list_species_in_order(region_id) do
    names = list_species_with_common_names() |> Enum.into(%{})
    schedules = list_schedules(region_id)
    today = MyDateTime.utc_today()

    for schedule <- schedules do
      {sd, ed} =
        Planner.unwrwap_dates(
          schedule.start_month,
          schedule.start_day,
          schedule.end_month,
          schedule.end_day,
          today
        )

      {sd, ed, schedule}
    end
    |> Enum.sort_by(&elem(&1, 0), Date)
    |> Enum.flat_map(fn {sd, ed, schedule} ->
      [
        {sd, ed, schedule},
        {Timex.shift(sd, years: 1), Timex.shift(ed, years: 1), schedule}
      ]
    end)
    |> Enum.map(fn {sd, ed, schedule} ->
      {:ok, date_str} = MyDateTime.relative_clamp_today(sd)

      remaining_days =
        if Timex.before?(MyDateTime.utc_today(), ed) && Timex.after?(MyDateTime.utc_today(), sd) do
          Timex.diff(ed, MyDateTime.utc_today(), :days)
        else
          nil
        end

      %{
        date_str: date_str,
        date: sd,
        species_name: names[schedule.species],
        remaining_days: remaining_days
      }
    end)
    |> Enum.group_by(& &1.date_str)
    |> Enum.sort_by(
      fn
        {_, [a | _]} -> a.date
      end,
      Date
    )
    |> Enum.map(fn {a, b} -> {a, Enum.sort_by(b, & &1.remaining_days)} end)
    |> Enum.take(3)
  end

  @doc """
  Gets a single species.

  Raises `Ecto.NoResultsError` if the Species does not exist.

  ## Examples

      iex> get_species!(123)
      %Species{}

      iex> get_species!(456)
      ** (Ecto.NoResultsError)

  """
  def get_species!(id), do: Repo.get!(Species, id)

  def get_any_season() do
    get_species_by_common_name("Any Season")
  end

  def list_common_species() do
    Repo.all(from s in Species, where: not is_nil(s.common_name))
  end

  @doc """
  Creates a species.

  ## Examples

      iex> create_species(%{field: value})
      {:ok, %Species{}}

      iex> create_species(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_species(attrs \\ %{}) do
    # TODO when species are created we need to make sure the ancestry tree also exists
    %Species{}
    |> Species.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a species.

  ## Examples

      iex> update_species(species, %{field: new_value})
      {:ok, %Species{}}

      iex> update_species(species, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_species(%Species{} = species, attrs) do
    species
    |> Species.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a species.

  ## Examples

      iex> delete_species(species)
      {:ok, %Species{}}

      iex> delete_species(species)
      {:error, %Ecto.Changeset{}}

  """
  def delete_species(%Species{} = species) do
    Repo.delete(species)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking species changes.

  ## Examples

      iex> change_species(species)
      %Ecto.Changeset{data: %Species{}}

  """
  def change_species(%Species{} = species, attrs \\ %{}) do
    Species.changeset(species, attrs)
  end

  alias VisualGarden.Library.Region

  @doc """
  Returns the list of regions.

  ## Examples

      iex> list_regions()
      [%Region{}, ...]

  """
  def list_regions do
    Repo.all(Region)
  end

  @doc """
  Gets a single region.

  Raises `Ecto.NoResultsError` if the Region does not exist.

  ## Examples

      iex> get_region!(123)
      %Region{}

      iex> get_region!(456)
      ** (Ecto.NoResultsError)

  """
  def get_region!(id), do: Repo.get!(Region, id)

  @doc """
  Creates a region.

  ## Examples

      iex> create_region(%{field: value})
      {:ok, %Region{}}

      iex> create_region(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_region(attrs \\ %{}) do
    %Region{}
    |> Region.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a region.

  ## Examples

      iex> update_region(region, %{field: new_value})
      {:ok, %Region{}}

      iex> update_region(region, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_region(%Region{} = region, attrs) do
    region
    |> Region.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a region.

  ## Examples

      iex> delete_region(region)
      {:ok, %Region{}}

      iex> delete_region(region)
      {:error, %Ecto.Changeset{}}

  """
  def delete_region(%Region{} = region) do
    Repo.delete(region)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking region changes.

  ## Examples

      iex> change_region(region)
      %Ecto.Changeset{data: %Region{}}

  """
  def change_region(%Region{} = region, attrs \\ %{}) do
    Region.changeset(region, attrs)
  end

  alias VisualGarden.Library.Schedule

  @doc """
  Returns the list of schedules.

  ## Examples

      iex> list_schedules()
      [%Schedule{}, ...]

  """
  def list_schedules do
    Repo.all(Schedule) |> Repo.preload([:region, :species])
  end

  def list_schedules(region_id) do
    Repo.all(from s in Schedule, where: s.region_id == ^region_id, preload: [:region, :species])
  end

  @doc """
  Gets a single schedule.

  Raises `Ecto.NoResultsError` if the Schedule does not exist.

  ## Examples

      iex> get_schedule!(123)
      %Schedule{}

      iex> get_schedule!(456)
      ** (Ecto.NoResultsError)

  """
  def get_schedule!(id), do: Repo.get!(Schedule, id) |> Repo.preload([:region, :species])

  @doc """
  Creates a schedule.

  ## Examples

      iex> create_schedule(%{field: value})
      {:ok, %Schedule{}}

      iex> create_schedule(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_schedule(attrs \\ %{}) do
    %Schedule{}
    |> Schedule.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a schedule.

  ## Examples

      iex> update_schedule(schedule, %{field: new_value})
      {:ok, %Schedule{}}

      iex> update_schedule(schedule, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_schedule(%Schedule{} = schedule, attrs) do
    schedule
    |> Schedule.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a schedule.

  ## Examples

      iex> delete_schedule(schedule)
      {:ok, %Schedule{}}

      iex> delete_schedule(schedule)
      {:error, %Ecto.Changeset{}}

  """
  def delete_schedule(%Schedule{} = schedule) do
    Repo.delete(schedule)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking schedule changes.

  ## Examples

      iex> change_schedule(schedule)
      %Ecto.Changeset{data: %Schedule{}}

  """
  def change_schedule(%Schedule{} = schedule, attrs \\ %{}) do
    Schedule.changeset(schedule, attrs)
  end

  alias VisualGarden.Library.LibrarySeed

  @doc """
  Returns the list of library_seeds.

  ## Examples

      iex> list_library_seeds()
      [%LibrarySeed{}, ...]

  """
  def list_library_seeds do
    Repo.all(LibrarySeed)
  end

  @doc """
  Gets a single library_seed.

  Raises `Ecto.NoResultsError` if the Library seed does not exist.

  ## Examples

      iex> get_library_seed!(123)
      %LibrarySeed{}

      iex> get_library_seed!(456)
      ** (Ecto.NoResultsError)

  """
  def get_library_seed!(id), do: Repo.get!(LibrarySeed, id) |> Repo.preload([:species])

  def get_library_seed_by_uuid(uuid) do
    Repo.one(from s in LibrarySeed, where: s.uuid == ^uuid)
  end

  @doc """
  Creates a library_seed.

  ## Examples

      iex> create_library_seed(%{field: value})
      {:ok, %LibrarySeed{}}

      iex> create_library_seed(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_library_seed(attrs \\ %{}) do
    %LibrarySeed{}
    |> LibrarySeed.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a library_seed.

  ## Examples

      iex> update_library_seed(library_seed, %{field: new_value})
      {:ok, %LibrarySeed{}}

      iex> update_library_seed(library_seed, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_library_seed(%LibrarySeed{} = library_seed, attrs) do
    library_seed
    |> LibrarySeed.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a library_seed.

  ## Examples

      iex> delete_library_seed(library_seed)
      {:ok, %LibrarySeed{}}

      iex> delete_library_seed(library_seed)
      {:error, %Ecto.Changeset{}}

  """
  def delete_library_seed(%LibrarySeed{} = library_seed) do
    Repo.delete(library_seed)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking library_seed changes.

  ## Examples

      iex> change_library_seed(library_seed)
      %Ecto.Changeset{data: %LibrarySeed{}}

  """
  def change_library_seed(%LibrarySeed{} = library_seed, attrs \\ %{}) do
    LibrarySeed.changeset(library_seed, attrs)
  end

  def change_planner_entry(%PlannerEntry{} = entry, attrs \\ %{}, garden) do
    PlannerEntry.changeset(entry, attrs, garden)
  end

  def specific_species_for_plant(region, species, dtm) do
    query =
      from sp in Species,
        join: ss in SpeciesSchedule,
        on: sp.id == ss.species_id,
        join: sc in Schedule,
        on: sc.id == ss.schedule_id,
        where: sc.region_id == ^region.id,
        where: sp.name == ^species.name,
        where: sp.genus == ^species.genus,
        where: not is_nil(sp.days_to_maturity)

    query =
      if species.variant do
        from sp in query,
          where: sp.variant == ^species.variant
      else
        from sp in query,
          where: is_nil(sp.variant)
      end

    query =
      if species.cultivar do
        from sp in query,
          where: sp.variant == ^species.cultivar
      else
        from sp in query,
          where: is_nil(sp.cultivar)
      end

    query
    |> Repo.all()
    |> Enum.map(&{&1, (&1.days_to_maturity - dtm) ** 2})
    |> Enum.group_by(fn {_, b} -> b end)
    |> Enum.map(fn {_b, xs} ->
      Enum.sort_by(xs, fn {a, _} -> a.days_to_maturity end)
      |> List.last()
    end)
    |> Enum.sort_by(fn {_a, b} -> b end)
    |> List.first()
    |> elem(0)
  end
end
