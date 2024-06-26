defmodule VisualGardenWeb.PlantLiveTest do
  alias VisualGarden.Planner
  alias VisualGarden.Gardens
  use VisualGardenWeb.ConnCase

  import Phoenix.LiveViewTest
  import VisualGarden.GardensFixtures
  import VisualGarden.AccountsFixtures

  @create_attrs %{name: "my plant", qty: 1}
  @update_attrs %{name: "my plant 2"}
  @invalid_attrs %{name: nil}

  defp create_plant(_) do
    garden = garden_fixture()
    product = product_fixture(%{type: "bed", length: 3, width: 4}, garden)
    plant = plant_fixture(%{product_id: product.id}, garden)
    user = user_fixture()
    Gardens.create_garden_user(garden, user)
    %{plant: plant, product: product, garden: garden, user: user}
  end

  describe "Index" do
    setup [:create_plant]

    test "lists all plants", %{conn: conn, garden: garden, user: user} do
      conn = log_in_user(conn, user)
      {:ok, _index_live, html} = live(conn, ~p"/gardens/#{garden.id}/plants")

      assert html =~ "Listing Plants"
    end

    test "lists all plants under product", %{
      conn: conn,
      garden: garden,
      product: product,
      user: user
    } do
      conn = log_in_user(conn, user)
      {:ok, _index_live, html} = live(conn, ~p"/gardens/#{garden.id}/beds/#{product.id}/plants")

      assert html =~ "Listing Plants"
    end

    # test "saves new plant from plants view", %{conn: conn, garden: garden, product: product} do
    #   {:ok, index_live, _html} = live(conn, ~p"/gardens/#{garden.id}/plants")

    #   assert index_live |> element("a", "New Plant") |> render_click() =~
    #            "New Plant"

    #   assert_patch(index_live, ~p"/gardens/#{garden.id}/plants/new")

    #   assert index_live
    #          |> form("#plant-form", plant: @invalid_attrs)
    #          |> render_change() =~ "can&#39;t be blank"

    #   index_live
    #          |> form("#plant-form", plant: Map.merge(@create_attrs, %{product_id: product.id}))
    #          |> render_change()

    #   assert index_live
    #          |> form("#plant-form", Square: "9", plant: Map.merge(@create_attrs, %{product_id: product.id}))
    #          |> render_submit()

    #   assert_patch(index_live, ~p"/gardens/#{garden.id}/plants")

    #   html = render(index_live)
    #   assert html =~ "Plant created successfully"
    # end

    test "updates plant in listing", %{
      conn: conn,
      plant: plant,
      garden: garden,
      product: product,
      user: user
    } do
      conn = log_in_user(conn, user)
      {:ok, index_live, _html} = live(conn, ~p"/gardens/#{garden.id}/plants")

      assert index_live |> element("#plants-#{plant.id} a", "Edit") |> render_click() =~
               "Edit Plant"

      assert_patch(index_live, ~p"/gardens/#{garden.id}/beds/#{product.id}/plants/#{plant}/edit")

      assert index_live
             |> form("#plant-form", plant: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#plant-form", plant: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/gardens/#{garden.id}/plants")

      html = render(index_live)
      assert html =~ "Plant updated successfully"
    end

    test "deletes plant in listing", %{conn: conn, plant: plant, garden: garden, user: user} do
      conn = log_in_user(conn, user)
      {:ok, index_live, _html} = live(conn, ~p"/gardens/#{garden.id}/plants")

      assert index_live |> element("#plants-#{plant.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#plants-#{plant.id}")
    end
  end

  describe "Show" do
    setup [:create_plant]

    test "displays plant", %{
      conn: conn,
      plant: plant,
      garden: garden,
      product: product,
      user: user
    } do
      conn = log_in_user(conn, user)

      {:ok, _show_live, html} =
        live(conn, ~p"/gardens/#{garden.id}/beds/#{product.id}/plants/#{plant}")

      assert html =~ "Show Plant"
    end

    test "updates plant within modal", %{
      conn: conn,
      plant: plant,
      garden: garden,
      product: product,
      user: user
    } do
      conn = log_in_user(conn, user)

      {:ok, show_live, _html} =
        live(conn, ~p"/gardens/#{garden.id}/beds/#{product.id}/plants/#{plant}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Plant"

      assert_patch(
        show_live,
        ~p"/gardens/#{garden.id}/beds/#{product.id}/plants/#{plant}/show/edit"
      )

      assert show_live
             |> form("#plant-form", plant: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#plant-form", plant: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/gardens/#{garden.id}/beds/#{product.id}/plants/#{plant}")

      html = render(show_live)
      assert html =~ "Plant updated successfully"
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

  describe "Tasks" do
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
      {:ok, index_live, _html} = live(conn, ~p"/gardens/#{garden.id}/plants")
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
      {:ok, index_live, _html} = live(conn, ~p"/gardens/#{garden.id}/plants")

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
      {:ok, index_live, _html} = live(conn, ~p"/gardens/#{garden.id}/plants")
      index_live |> element(".orphan-link") |> render_click()

      {path, flash} = assert_redirect(index_live)

      {:ok, index_live, _html} = live(conn, path)
      # assert_patch(
      #   index_live,
      #   ~p"/gardens/#{garden.id}/plants/orphaned_nursery/#{nursery_entry.id}"
      # )

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
