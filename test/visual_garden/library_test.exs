defmodule VisualGarden.LibraryTest do
  use VisualGarden.DataCase

  alias VisualGarden.Library

  describe "species" do
    alias VisualGarden.Library.Species

    import VisualGarden.LibraryFixtures

    @invalid_attrs %{name: nil}

    test "list_species/0 returns all species" do
      species = species_fixture()
      assert Library.list_species() == [species]
    end

    test "get_species!/1 returns the species with given id" do
      species = species_fixture()
      assert Library.get_species!(species.id) == species
    end

    test "create_species/1 with valid data creates a species" do
      valid_attrs = %{name: "some name", genus: "a genus"}

      assert {:ok, %Species{} = species} = Library.create_species(valid_attrs)
      assert species.name == "some name"
    end

    test "create_species/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Library.create_species(@invalid_attrs)
    end

    test "update_species/2 with valid data updates the species" do
      species = species_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Species{} = species} = Library.update_species(species, update_attrs)
      assert species.name == "some updated name"
    end

    test "update_species/2 with invalid data returns error changeset" do
      species = species_fixture()
      assert {:error, %Ecto.Changeset{}} = Library.update_species(species, @invalid_attrs)
      assert species == Library.get_species!(species.id)
    end

    test "delete_species/1 deletes the species" do
      species = species_fixture()
      assert {:ok, %Species{}} = Library.delete_species(species)
      assert_raise Ecto.NoResultsError, fn -> Library.get_species!(species.id) end
    end

    test "change_species/1 returns a species changeset" do
      species = species_fixture()
      assert %Ecto.Changeset{} = Library.change_species(species)
    end
  end

  describe "regions" do
    alias VisualGarden.Library.Region

    import VisualGarden.LibraryFixtures

    @invalid_attrs %{name: nil}

    test "list_regions/0 returns all regions" do
      region = region_fixture()
      assert Library.list_regions() == [region]
    end

    test "get_region!/1 returns the region with given id" do
      region = region_fixture()
      assert Library.get_region!(region.id) == region
    end

    test "create_region/1 with valid data creates a region" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Region{} = region} = Library.create_region(valid_attrs)
      assert region.name == "some name"
    end

    test "create_region/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Library.create_region(@invalid_attrs)
    end

    test "update_region/2 with valid data updates the region" do
      region = region_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Region{} = region} = Library.update_region(region, update_attrs)
      assert region.name == "some updated name"
    end

    test "update_region/2 with invalid data returns error changeset" do
      region = region_fixture()
      assert {:error, %Ecto.Changeset{}} = Library.update_region(region, @invalid_attrs)
      assert region == Library.get_region!(region.id)
    end

    test "delete_region/1 deletes the region" do
      region = region_fixture()
      assert {:ok, %Region{}} = Library.delete_region(region)
      assert_raise Ecto.NoResultsError, fn -> Library.get_region!(region.id) end
    end

    test "change_region/1 returns a region changeset" do
      region = region_fixture()
      assert %Ecto.Changeset{} = Library.change_region(region)
    end
  end

  describe "schedules" do
    alias VisualGarden.Library.Schedule

    import VisualGarden.LibraryFixtures

    @invalid_attrs %{
      start_month: nil,
      start_day: nil,
      end_month: nil,
      end_day: nil,
      end_month_adjusted: nil
    }

    test "list_schedules/0 returns all schedules" do
      schedule = schedule_fixture()
      assert Library.list_schedules() == [Repo.preload(schedule, [:species, :region])]
    end

    test "get_schedule!/1 returns the schedule with given id" do
      schedule = schedule_fixture()
      assert Library.get_schedule!(schedule.id) == Repo.preload(schedule, [:region, :species])
    end

    test "create_schedule/1 with valid data creates a schedule" do
      species = species_fixture()
      region = region_fixture()

      valid_attrs = %{
        start_month: 3,
        start_day: 42,
        end_month: 1,
        end_day: 42,
        species_id: species.id,
        region_id: region.id
      }

      assert {:ok, %Schedule{} = schedule} = Library.create_schedule(valid_attrs)
      assert schedule.start_month == 3
      assert schedule.start_day == 42
      assert schedule.end_month == 1
      assert schedule.end_day == 42
      assert schedule.end_month_adjusted == 13
    end

    test "create_schedule/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Library.create_schedule(@invalid_attrs)
    end

    test "update_schedule/2 with valid data updates the schedule" do
      schedule = schedule_fixture()

      update_attrs = %{
        start_month: 43,
        start_day: 43,
        end_month: 43,
        end_day: 43,
        end_month_adjusted: 43
      }

      assert {:ok, %Schedule{} = schedule} = Library.update_schedule(schedule, update_attrs)
      assert schedule.start_month == 43
      assert schedule.start_day == 43
      assert schedule.end_month == 43
      assert schedule.end_day == 43
      assert schedule.end_month_adjusted == 55
    end

    test "update_schedule/2 with invalid data returns error changeset" do
      schedule = schedule_fixture()
      assert {:error, %Ecto.Changeset{}} = Library.update_schedule(schedule, @invalid_attrs)
      assert Repo.preload(schedule, [:species, :region]) == Library.get_schedule!(schedule.id)
    end

    test "delete_schedule/1 deletes the schedule" do
      schedule = schedule_fixture()
      assert {:ok, %Schedule{}} = Library.delete_schedule(schedule)
      assert_raise Ecto.NoResultsError, fn -> Library.get_schedule!(schedule.id) end
    end

    test "change_schedule/1 returns a schedule changeset" do
      schedule = schedule_fixture()
      assert %Ecto.Changeset{} = Library.change_schedule(schedule)
    end
  end

  describe "library_seeds" do
    alias VisualGarden.Library.LibrarySeed

    import VisualGarden.LibraryFixtures

    @invalid_attrs %{type: nil, days_to_maturation: nil, manufacturer: nil}

    test "list_library_seeds/0 returns all library_seeds" do
      library_seed = library_seed_fixture()
      assert Library.list_library_seeds() == [library_seed]
    end

    test "get_library_seed!/1 returns the library_seed with given id" do
      library_seed = library_seed_fixture()
      assert Library.get_library_seed!(library_seed.id) == library_seed
    end

    test "create_library_seed/1 with valid data creates a library_seed" do
      species = species_fixture()

      valid_attrs = %{
        type: :slip,
        days_to_maturation: 42,
        manufacturer: "some manufacturer",
        species_id: species.id
      }

      assert {:ok, %LibrarySeed{} = library_seed} = Library.create_library_seed(valid_attrs)
      assert library_seed.type == :slip
      assert library_seed.days_to_maturation == 42
      assert library_seed.manufacturer == "some manufacturer"
    end

    test "create_library_seed/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Library.create_library_seed(@invalid_attrs)
    end

    test "update_library_seed/2 with valid data updates the library_seed" do
      library_seed = library_seed_fixture()

      update_attrs = %{
        type: :seed,
        days_to_maturation: 43,
        manufacturer: "some updated manufacturer"
      }

      assert {:ok, %LibrarySeed{} = library_seed} =
               Library.update_library_seed(library_seed, update_attrs)

      assert library_seed.type == :seed
      assert library_seed.days_to_maturation == 43
      assert library_seed.manufacturer == "some updated manufacturer"
    end

    test "update_library_seed/2 with invalid data returns error changeset" do
      library_seed = library_seed_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Library.update_library_seed(library_seed, @invalid_attrs)

      assert library_seed == Library.get_library_seed!(library_seed.id)
    end

    test "delete_library_seed/1 deletes the library_seed" do
      library_seed = library_seed_fixture()
      assert {:ok, %LibrarySeed{}} = Library.delete_library_seed(library_seed)
      assert_raise Ecto.NoResultsError, fn -> Library.get_library_seed!(library_seed.id) end
    end

    test "change_library_seed/1 returns a library_seed changeset" do
      library_seed = library_seed_fixture()
      assert %Ecto.Changeset{} = Library.change_library_seed(library_seed)
    end
  end
end
