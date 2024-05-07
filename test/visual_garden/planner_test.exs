defmodule VisualGarden.LibraryTest do
  alias VisualGarden.LibraryFixtures
  alias VisualGarden.GardensFixtures
  use VisualGarden.DataCase

  alias VisualGarden.Planner

  describe "date finagling" do
    @today ~D[2024-06-06]

    test "time comes after today" do
      assert {~D[2024-07-01], ~D[2024-08-01]} = Planner.unwrwap_dates(7, 1, 8, 1, @today)
    end

    test "overlaps today" do
      assert {~D[2024-05-01], ~D[2024-08-01]} = Planner.unwrwap_dates(5, 1, 8, 1, @today)
    end

    test "before today" do
      assert {~D[2025-03-01], ~D[2025-04-01]} = Planner.unwrwap_dates(3, 1, 4, 1, @today)
    end

    test "end is before start" do
      assert {~D[2024-03-01], ~D[2025-02-01]} = Planner.unwrwap_dates(3, 1, 2, 1, @today)
    end

    test "happy path" do
      region = LibraryFixtures.region_fixture(%{name: "foo"})
      garden = GardensFixtures.garden_fixture(%{region_id: region.id})
      bed = GardensFixtures.product_fixture( %{type: "bed", width: 3, length: 4}, garden)
      species = LibraryFixtures.species_fixture(%{name: "bar"})
      seed = GardensFixtures.seed_fixture(%{name: "my seed please"}, garden)

      schedule =
        LibraryFixtures.schedule_fixture(%{
          name: "a new schedule",
          region_id: region.id,
          species_id: species.id,
          start_month: 3,
          start_day: 1,
          end_month: 2,
          end_day: 1
        })

      today = ~D[2024-06-06]
      assert :ok = Planner.get_plantables_from_garden(bed, ~D[2024-05-06], nil, today)
    end
  end
end
