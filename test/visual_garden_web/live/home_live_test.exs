defmodule VisualGardenWeb.HomeLiveTest do
  alias VisualGarden.Planner
  alias VisualGarden.Gardens
  use VisualGardenWeb.ConnCase

  import Phoenix.LiveViewTest
  import VisualGarden.GardensFixtures
  import VisualGarden.LibraryFixtures
  import VisualGarden.AccountsFixtures

  def setup_garden(_) do
    garden = garden_fixture()
    user = user_fixture()
    Gardens.create_garden_user(garden, user)
    seed = seed_fixture(%{}, garden)
    bed = product_fixture(%{type: :bed, length: 3, width: 4}, garden)

    %{garden: garden, user: user, seed: seed, bed: bed}
  end

  describe "Index" do
    setup [:setup_garden]

    test "nursery todo current", %{garden: garden, bed: bed, seed: seed, user: user, conn: conn} do
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
            column: 1,
            min_lead: min_lead,
            max_lead: max_lead
          },
          garden
        )

      conn = log_in_user(conn, user)
      {:ok, index_live, _html} = live(conn, ~p"/home")
      index_live |> element("button", "Nurse") |> render_click()

      assert length(Gardens.list_nursery_entries(garden.id)) == 1
    end

    test "plant todo current", %{garden: garden, bed: bed, seed: seed, user: user, conn: conn} do
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

      conn = log_in_user(conn, user)
      {:ok, index_live, _html} = live(conn, ~p"/home")
      index_live |> element("button", "Plant") |> render_click()

      assert length(Gardens.list_plants(garden.id)) == 1
    end

    test "planting an orphaned nursery", %{
      garden: garden,
      bed: bed,
      seed: seed,
      user: user,
      conn: conn
    } do
      nursery_entry =
        nursery_entry_fixture(garden, %{
          sow_date: ~D[2023-04-01],
          seed_id: seed.id
        })

      [%{bed_id: bid, row: r, col: c, end_date: end_date} | _] =
        Planner.get_open_slots(
          garden,
          Timex.shift(nursery_entry.sow_date, days: seed.days_to_maturation)
        )

      conn = log_in_user(conn, user)
      {:ok, index_live, _html} = live(conn, ~p"/home")
      index_live |> element(".orphan-link") |> render_click()

      assert_patch(index_live, ~p"/home/orphaned_nursery/#{nursery_entry.id}")

      assert index_live
             |> form("#orphan-form",
               orphan_schema: %{bed_id: bid}
             )
             |> render_change()

      assert index_live
             |> form("#orphan-form",
               orphan_schema: %{square: 1}
             )
             |> render_change()

      assert index_live
             |> form("#orphan-form",
               orphan_schema: %{refuse_date: ~D[2023-06-01]}
             )
             |> render_submit()
    end
  end
end
