defmodule VisualGarden.WizardTest do
  alias VisualGarden.Planner
  alias VisualGarden.GardensFixtures
  alias VisualGarden.LibraryFixtures
  alias VisualGarden.MyDateTime
  use VisualGarden.DataCase
  alias VisualGarden.Wizard

  test "convert_plantables_to_optimizer/1" do
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
        end_day: 1,
        plantable_types: ["seed"]
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
        nursery_lead_weeks_min: 2,
        plantable_types: ["seed"]
      })

    today = MyDateTime.utc_today()

    # Planner.get_plantables_from_garden(bed, today, nil, today)
    # |> IO.inspect()
  end

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
end
