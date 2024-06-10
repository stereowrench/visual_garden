defmodule VisualGardenWeb.PlannerLiveTest do
  alias VisualGarden.Library
  use VisualGardenWeb.ConnCase

  import Phoenix.LiveViewTest
  import VisualGarden.LibraryFixtures
  import VisualGarden.GardensFixtures
  import VisualGarden.AccountsFixtures

  test "happy path", %{conn: conn} do
    user = user_fixture()
    region = region_fixture()
    garden = garden_fixture(%{owner_id: user.id, region_id: region.id})
    seed = seed_fixture(%{days_to_maturation: 30}, garden)
    species = Library.get_species!(seed.species_id)
    {:ok, species} = Library.update_species(species, %{common_name: "Onion"})
    bed = product_fixture(%{type: "bed", length: 4, width: 5}, garden)

    conn = log_in_user(conn, user)

    schedule =
      schedule_fixture(%{
        region_id: region.id,
        species_id: species.id,
        end_month: 8,
        end_day: 1,
        start_month: 7,
        start_day: 1,
        plantable_types: ["seed"]
      })

    {:ok, show_live, _html} = live(conn, ~p"/planners/#{garden.id}")
    show_live |> element("svg > a:first-of-type") |> render_click()
    assert_patch(show_live, ~p"/planners/#{garden.id}/#{bed.id}/0/new?start_date=2023-06-06")

    show_live |> form("#planner-form", species: species.common_name) |> render_change()
    show_live |> form("#planner-form", type: "seed -- some name") |> render_change()
    show_live |> form("#planner-form", plantable: "0") |> render_change()

    show_live
    |> form("#planner-form",
      planner_entry: %{start_plant_date: ~D[2023-07-02], end_plant_date: ~D[2023-07-20]}
    )
    |> render_change()

    assert show_live
           |> form("#planner-form",
             refuse_date: ~D[2023-11-01]
           )
           |> render_submit() =~ "Onion"
  end
end
