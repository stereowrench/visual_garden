defmodule VisualGarden.LibraryTest do
  use VisualGarden.DataCase

  alias VisualGarden.Library

  describe "genera" do
    alias VisualGarden.Library.Genus

    import VisualGarden.LibraryFixtures

    @invalid_attrs %{name: nil}

    test "list_genera/0 returns all genera" do
      genus = genus_fixture()
      assert Library.list_genera() == [genus]
    end

    test "get_genus!/1 returns the genus with given id" do
      genus = genus_fixture()
      assert Library.get_genus!(genus.id) == genus
    end

    test "create_genus/1 with valid data creates a genus" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Genus{} = genus} = Library.create_genus(valid_attrs)
      assert genus.name == "some name"
    end

    test "create_genus/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Library.create_genus(@invalid_attrs)
    end

    test "update_genus/2 with valid data updates the genus" do
      genus = genus_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Genus{} = genus} = Library.update_genus(genus, update_attrs)
      assert genus.name == "some updated name"
    end

    test "update_genus/2 with invalid data returns error changeset" do
      genus = genus_fixture()
      assert {:error, %Ecto.Changeset{}} = Library.update_genus(genus, @invalid_attrs)
      assert genus == Library.get_genus!(genus.id)
    end

    test "delete_genus/1 deletes the genus" do
      genus = genus_fixture()
      assert {:ok, %Genus{}} = Library.delete_genus(genus)
      assert_raise Ecto.NoResultsError, fn -> Library.get_genus!(genus.id) end
    end

    test "change_genus/1 returns a genus changeset" do
      genus = genus_fixture()
      assert %Ecto.Changeset{} = Library.change_genus(genus)
    end
  end

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
      valid_attrs = %{name: "some name"}

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

    @invalid_attrs %{start_month: nil, start_day: nil, end_month: nil, end_day: nil, end_month_adjusted: nil}

    test "list_schedules/0 returns all schedules" do
      schedule = schedule_fixture()
      assert Library.list_schedules() == [schedule]
    end

    test "get_schedule!/1 returns the schedule with given id" do
      schedule = schedule_fixture()
      assert Library.get_schedule!(schedule.id) == schedule
    end

    test "create_schedule/1 with valid data creates a schedule" do
      valid_attrs = %{start_month: 3, start_day: 42, end_month: 1, end_day: 42}

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
      update_attrs = %{start_month: 43, start_day: 43, end_month: 43, end_day: 43, end_month_adjusted: 43}

      assert {:ok, %Schedule{} = schedule} = Library.update_schedule(schedule, update_attrs)
      assert schedule.start_month == 43
      assert schedule.start_day == 43
      assert schedule.end_month == 43
      assert schedule.end_day == 43
      assert schedule.end_month_adjusted == 43
    end

    test "update_schedule/2 with invalid data returns error changeset" do
      schedule = schedule_fixture()
      assert {:error, %Ecto.Changeset{}} = Library.update_schedule(schedule, @invalid_attrs)
      assert schedule == Library.get_schedule!(schedule.id)
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
end
