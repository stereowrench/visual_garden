defmodule VisualGarden.PlannerTest do
  alias VisualGarden.Gardens
  alias VisualGarden.LibraryFixtures
  alias VisualGarden.GardensFixtures
  use VisualGarden.DataCase

  alias VisualGarden.Planner
  import VisualGarden.GardensFixtures
  import VisualGarden.AccountsFixtures
  import VisualGarden.LibraryFixtures

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
                 nursery_end: ~D[2025-05-18],
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
                 nursery_end: ~D[2024-06-23],
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

  def setup_garden(_) do
    garden = garden_fixture()
    user = user_fixture()
    Gardens.create_garden_user(garden, user)
    seed = seed_fixture(%{}, garden)
    bed = product_fixture(%{type: :bed, length: 3, width: 4}, garden)

    %{garden: garden, user: user, seed: seed, bed: bed}
  end

  describe "todo list" do
    setup [:setup_garden]

    test "nursery todo current", %{garden: garden, bed: bed, seed: seed, user: user} do
      ns = ~D[2023-06-05]
      ne = ~D[2023-06-15]
      min_lead = 2
      max_lead = 4

      {:ok, pe} =
        Planner.create_planner_entry(
          %{
            nursery_start: ns,
            nursery_end: ne,
            start_plant_date: Timex.shift(ns, weeks: min_lead),
            end_plant_date: Timex.shift(ne, weeks: max_lead),
            days_to_maturity: 30,
            days_to_refuse: 15,
            common_name: "Mine",
            bed_id: bed.id,
            seed_id: seed.id,
            row: 1,
            column: 1
          },
          garden
        )

      assert Planner.get_todo_items(user) == [
               %{
                 type: "nursery_plant",
                 planner_entry_id: pe.id,
                 date: ~D[2023-06-06],
                 end_date: ne
               }
             ]
    end

    test "nursery todo future", %{garden: garden, bed: bed, seed: seed, user: user} do
      ns = ~D[2023-07-05]
      ne = ~D[2023-07-15]
      min_lead = 2
      max_lead = 4

      {:ok, pe} =
        Planner.create_planner_entry(
          %{
            nursery_start: ns,
            nursery_end: ne,
            start_plant_date: Timex.shift(ns, weeks: min_lead),
            end_plant_date: Timex.shift(ne, weeks: max_lead),
            days_to_maturity: 30,
            days_to_refuse: 15,
            common_name: "Mine",
            bed_id: bed.id,
            seed_id: seed.id,
            row: 1,
            column: 1
          },
          garden
        )

      assert Planner.get_todo_items(user) == [
               %{
                 type: "nursery_plant",
                 planner_entry_id: pe.id,
                 date: ~D[2023-07-05],
                 end_date: ne
               }
             ]
    end

    test "nursery todo overdue", %{garden: garden, bed: bed, seed: seed, user: user} do
      ns = ~D[2023-05-05]
      ne = ~D[2023-05-15]
      min_lead = 2
      max_lead = 4

      {:ok, pe} =
        Planner.create_planner_entry(
          %{
            nursery_start: ns,
            nursery_end: ne,
            start_plant_date: Timex.shift(ns, weeks: min_lead),
            end_plant_date: Timex.shift(ne, weeks: max_lead),
            days_to_maturity: 30,
            days_to_refuse: 15,
            common_name: "Mine",
            bed_id: bed.id,
            seed_id: seed.id,
            row: 1,
            column: 1
          },
          garden
        )

      assert Planner.get_todo_items(user) == [
               %{
                 type: "nursery_overdue",
                 planner_entry_id: pe.id,
                 date: ~D[2023-05-15]
               }
             ]
    end

    test "plant todo current", %{garden: garden, bed: bed, seed: seed, user: user} do
      plants = ~D[2023-06-05]
      plante = ~D[2023-06-15]

      {:ok, pe} =
        Planner.create_planner_entry(
          %{
            start_plant_date: plants,
            end_plant_date: plante,
            days_to_maturity: 30,
            days_to_refuse: 15,
            common_name: "Mine",
            bed_id: bed.id,
            seed_id: seed.id,
            row: 1,
            column: 1
          },
          garden
        )

      assert Planner.get_todo_items(user) == [
               %{
                 type: "plant",
                 planner_entry_id: pe.id,
                 date: ~D[2023-06-06],
                 end_date: plante
               }
             ]
    end

    test "plant todo future", %{garden: garden, bed: bed, seed: seed, user: user} do
      plants = ~D[2023-07-05]
      plante = ~D[2023-07-15]

      {:ok, pe} =
        Planner.create_planner_entry(
          %{
            start_plant_date: plants,
            end_plant_date: plante,
            days_to_maturity: 30,
            days_to_refuse: 15,
            common_name: "Mine",
            bed_id: bed.id,
            seed_id: seed.id,
            row: 1,
            column: 1
          },
          garden
        )

      assert Planner.get_todo_items(user) == [
               %{
                 type: "plant",
                 planner_entry_id: pe.id,
                 date: ~D[2023-07-05],
                 end_date: plante
               }
             ]
    end

    test "plant todo overdue", %{garden: garden, bed: bed, seed: seed, user: user} do
      plants = ~D[2023-05-05]
      plante = ~D[2023-05-15]

      {:ok, pe} =
        Planner.create_planner_entry(
          %{
            start_plant_date: plants,
            end_plant_date: plante,
            days_to_maturity: 30,
            days_to_refuse: 15,
            common_name: "Mine",
            bed_id: bed.id,
            seed_id: seed.id,
            row: 1,
            column: 1
          },
          garden
        )

      assert Planner.get_todo_items(user) == [
               %{
                 type: "plant_overdue",
                 planner_entry_id: pe.id,
                 date: ~D[2023-05-15]
               }
             ]
    end

    test "planted plants don't appear", %{garden: garden, bed: bed, seed: seed, user: user} do
      plants = ~D[2023-06-05]
      plante = ~D[2023-06-15]

      {:ok, pe} =
        Planner.create_planner_entry(
          %{
            start_plant_date: plants,
            end_plant_date: plante,
            days_to_maturity: 30,
            days_to_refuse: 15,
            common_name: "Mine",
            bed_id: bed.id,
            seed_id: seed.id,
            row: 1,
            column: 1
          },
          garden
        )

      {:ok, plant} =
        Gardens.create_plant(%{name: "My plant", qty: 1, row: 1, column: 1, product_id: bed.id})

      {:ok, _} = Planner.set_planner_entry_plant(pe, plant.id, garden)

      assert Planner.get_todo_items(user) == []
    end

    test "nursed plants don't appear", %{garden: garden, bed: bed, seed: seed, user: user} do
      ns = ~D[2023-06-05]
      ne = ~D[2023-06-15]
      min_lead = 2
      max_lead = 4

      {:ok, pe} =
        Planner.create_planner_entry(
          %{
            nursery_start: ns,
            nursery_end: ne,
            start_plant_date: Timex.shift(ns, weeks: min_lead),
            end_plant_date: Timex.shift(ne, weeks: max_lead),
            days_to_maturity: 30,
            days_to_refuse: 15,
            common_name: "Mine",
            bed_id: bed.id,
            seed_id: seed.id,
            row: 1,
            column: 1
          },
          garden
        )

      Gardens.create_nursery_entry(%{
        sow_date: ns,
        planner_entry_id: pe.id,
        seed_id: seed.id,
        garden_id: garden.id
      })

      assert Planner.get_todo_items(user) == [
               %{
                 type: "plant",
                 date: ~D[2023-06-19],
                 end_date: ~D[2023-07-13],
                 planner_entry_id: pe.id
               }
             ]
    end

    test "water" do
    end
  end
end
