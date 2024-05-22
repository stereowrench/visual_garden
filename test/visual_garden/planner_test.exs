defmodule VisualGarden.PlannerTest do
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
      bed = GardensFixtures.product_fixture(%{type: "bed", width: 3, length: 4}, garden)
      species = LibraryFixtures.species_fixture(%{name: "bar"})

      seed =
        GardensFixtures.seed_fixture(%{name: "my seed please", species_id: species.id}, garden)

      schedule =
        LibraryFixtures.schedule_fixture(%{
          name: "a new schedule",
          region_id: region.id,
          species_id: species.id,
          start_month: 7,
          start_day: 1,
          end_month: 1,
          end_day: 1
        })

      schedule2 =
        LibraryFixtures.schedule_fixture(%{
          name: "a new schedule",
          region_id: region.id,
          species_id: species.id,
          start_month: 5,
          start_day: 1,
          end_month: 6,
          end_day: 1,
          nursery_lead_weeks_max: 4,
          nursery_lead_weeks_min: 2
        })

      today = ~D[2024-06-06]

      assert [
               %{
                 type: :seed,
                 days: 51,
                 sow_start: ~D[2024-07-01],
                 sow_end: ~D[2025-01-01]
               },
               %{
                 type: :seed,
                 days: 51,
                 sow_start: ~D[2025-05-01],
                 sow_end: ~D[2025-06-01]
               },
               %{
                 type: "nursery",
                 days: 51,
                 sow_start: ~D[2025-04-17],
                 sow_end: ~D[2025-06-01],
                 nursery_end: ~D[2025-04-11],
                 nursery_start: ~D[2025-04-03]
               }
             ] =
               Planner.get_plantables_from_garden(bed, ~D[2024-05-06], nil, today)
    end

    test "end date happy path" do
      region = LibraryFixtures.region_fixture(%{name: "foo"})
      garden = GardensFixtures.garden_fixture(%{region_id: region.id})
      bed = GardensFixtures.product_fixture(%{type: "bed", width: 3, length: 4}, garden)
      species = LibraryFixtures.species_fixture(%{name: "bar"})

      seed =
        GardensFixtures.seed_fixture(
          %{name: "my seed please", species_id: species.id, days_to_maturation: 10},
          garden
        )

      schedule =
        LibraryFixtures.schedule_fixture(%{
          name: "a new schedule",
          region_id: region.id,
          species_id: species.id,
          start_month: 6,
          start_day: 6,
          end_month: 6,
          end_day: 30,
          nursery_lead_weeks_max: 4,
          nursery_lead_weeks_min: 1
        })

      today = ~D[2024-06-06]

      assert [
               %{days: 10, sow_end: ~D[2024-06-30], sow_start: ~D[2024-06-06], type: :seed},
               %{
                 type: "nursery",
                 days: 10,
                 sow_start: ~D[2024-06-13],
                 sow_end: ~D[2024-06-30],
                 nursery_end: ~D[2024-06-20],
                 nursery_start: ~D[2024-06-06]
               }
             ] =
               Planner.get_plantables_from_garden(bed, ~D[2024-05-06], ~D[2024-07-26], today)
    end
  end

  describe "bed encoding" do
    test "testing" do
      for j <- 0..5 do
        for i <- 0..10 do
          bed1 = %{length: 6, width: 11}

          assert {^i, ^j} =
                   Planner.parse_square(
                     VisualGardenWeb.PlannerLive.GraphComponent.bed_square(
                       %{row: i, column: j},
                       bed1
                     )
                     |> to_string(),
                     bed1
                   )

          bed2 = %{length: 11, width: 6}

          assert {^j, ^i} =
                   Planner.parse_square(
                     VisualGardenWeb.PlannerLive.GraphComponent.bed_square(
                       %{row: j, column: i},
                       bed2
                     )
                     |> to_string(),
                     bed2
                   )
        end
      end
    end
  end
end
