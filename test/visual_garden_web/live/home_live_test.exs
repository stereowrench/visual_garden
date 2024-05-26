defmodule VisualGardenWeb.HarvestLiveTest do
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
    end
  end
end
