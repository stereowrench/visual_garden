defmodule VisualGarden.WizardTest do
  alias VisualGarden.Planner
  alias VisualGarden.GardensFixtures
  alias VisualGarden.LibraryFixtures
  alias VisualGarden.MyDateTime
  use VisualGarden.DataCase
  alias VisualGarden.Wizard

  # test "convert from optimizer output to planner entries" do
  #   region = LibraryFixtures.region_fixture(%{name: "foo"})
  #   garden = GardensFixtures.garden_fixture(%{region_id: region.id})
  #   bed = GardensFixtures.product_fixture(%{type: "bed", width: 3, length: 4}, garden)
  #   species = LibraryFixtures.species_fixture(%{name: "bar"})

  #   seed =
  #     GardensFixtures.seed_fixture(%{name: "my seed please", species_id: species.id}, garden)

  #   schedule =
  #     LibraryFixtures.schedule_fixture(%{
  #       name: "a new schedule",
  #       region_id: region.id,
  #       species_id: species.id,
  #       start_month: 7,
  #       start_day: 1,
  #       end_month: 1,
  #       end_day: 1,
  #       plantable_types: ["seed"]
  #     })

  #   schedule2 =
  #     LibraryFixtures.schedule_fixture(%{
  #       name: "a new schedule",
  #       region_id: region.id,
  #       species_id: species.id,
  #       start_month: 5,
  #       start_day: 1,
  #       end_month: 6,
  #       end_day: 1,
  #       nursery_lead_weeks_max: 4,
  #       nursery_lead_weeks_min: 2,
  #       plantable_types: ["seed"]
  #     })

  #   today = MyDateTime.utc_today()

  #   {windows, plants_map} =
  #     Planner.get_plantables_from_garden(bed, today, nil, today)
  #     |> Enum.flat_map(fn x ->
  #       for i <- 0..2 do
  #         for j <- 0..2 do
  #           Map.put(x, :place, {i, j})
  #         end
  #       end
  #       |> List.flatten()
  #     end)
  #     |> Wizard.convert_from_planner_to_optimizer(2, 2)

  #   Optimizer
  # end

  test "convert_plantables_to_optimizer sparse" do
    rows = 2
    cols = 2

    out =
      Wizard.convert_from_planner_to_optimizer(
        [
          %{
            place: {0, 0},
            seed: %{id: 1},
            type: :seed,
            sow_start: ~D[2024-01-01],
            sow_end: ~D[2024-02-01]
          },
          %{
            place: {0, 0},
            seed: %{id: 1},
            type: :seed,
            sow_start: ~D[2024-03-01],
            sow_end: ~D[2024-04-01]
          },
          %{
            place: {0, 0},
            seed: %{id: 1},
            type: :nursery,
            sow_start: ~D[2024-01-01],
            sow_end: ~D[2024-02-01]
          },
          %{
            place: {0, 1},
            seed: %{id: 1},
            type: :nursery,
            sow_start: ~D[2024-01-01],
            sow_end: ~D[2024-02-01]
          }
        ],
        rows,
        cols
      )

    {windows, type_map} = out

    assert %{1 => [:seed, :nursery]} = type_map

    seed1 = windows[1]
    seeded = Enum.at(seed1, 0)
    nursed = Enum.at(seed1, 1)

    assert [
             # row1
             [
               # col1
               [{_, _}, {_, _}],
               # col 2
               []
             ],
             # row 2
             [
               # col1
               [],
               # col 2
               []
             ]
           ] = seeded

    assert [
             # row1
             [
               # col1
               [{_, _}],
               # col 2
               [{_, _}]
             ],
             # row 2
             [
               # col1
               [],
               # col 2
               []
             ]
           ] = nursed

    assert %{
             1 => [
               # seeded
               [
                 # row 0
                 [
                   # col 0
                   [
                     {_, _},
                     {_, _}
                   ],
                   # col 1
                   []
                 ],
                 # row 1
                 [
                   [],
                   []
                 ]
               ],
               # nursed
               [
                 # row 0
                 [
                   # col0
                   [
                     {_, _}
                   ],
                   # col 1
                   [
                     {_, _}
                   ]
                 ],
                 [
                   [],
                   []
                 ]
               ]
             ]
           } = windows
  end

  def get_index_for_planting_type(plants, plant, type) do
    plants[plant]["planting_types"]
    |> Enum.with_index()
    |> Enum.find(fn {i, idx} -> i == type end)
    |> elem(1)
  end

  test "index for planting type works" do
    plants = %{"a" => %{"planting_types" => ~w(b c)}}
    assert get_index_for_planting_type(plants, "a", "b") == 0
    assert get_index_for_planting_type(plants, "a", "c") == 1
  end

  test "convert to planner entries" do
    sched =
      [
        %{
          "cols" => 1,
          "name" => "tomato",
          "rows" => 1,
          "type" => "transplant",
          "weeks" => 1,
          "x" => 0,
          "y" => 0
        },
        %{
          "cols" => 1,
          "name" => "tomato",
          "rows" => 1,
          "type" => "transplant",
          "weeks" => 1,
          "x" => 0,
          "y" => 1
        },
        %{
          "cols" => 1,
          "name" => "tomato",
          "rows" => 1,
          "type" => "transplant",
          "weeks" => 1,
          "x" => 1,
          "y" => 0
        },
        %{
          "cols" => 1,
          "name" => "tomato",
          "rows" => 1,
          "type" => "seed",
          "weeks" => 1,
          "x" => 1,
          "y" => 1
        }
      ]

    plants = %{
      "tomato" => %{"planting_types" => ["seed", "transplant"]}
    }

    planting_windows =
      %{
        "tomato" => [
          # seed
          [
            [[[1, 30]], [[1, 30]]],
            [[[1, 30]], [[1, 30]]]
          ],
          # transplant
          [
            [[[5, 35]], [[5, 35]]],
            [[[5, 35]], [[5, 35]]]
          ]
        ]
      }

    # if type is nursery
    # if type is not nursery

    sched
    |> Enum.map(fn x ->
      idx1 = get_index_for_planting_type(plants, x["name"], x["type"])

      time_slots =
        planting_windows[x["name"]]
        |> Enum.at(idx1)
        |> Enum.at(x["x"])
        |> Enum.at(x["y"])

      selected =
        Enum.find(time_slots, fn [st, en] ->
          st <= x["weeks"] * 7 && x["weeks"] * 7 <= en
        end)

      time_keys =
        if x["type"] == "nursery" do
        else
        end

      %{
        place: {x["x"], x["y"]}
      }
    end)
  end
end
