defmodule VisualGardenWeb.GardenLiveTest do
  use VisualGardenWeb.ConnCase

  import Phoenix.LiveViewTest
  import VisualGarden.GardensFixtures

  @create_attrs %{name: "My Garden 2"}
  @update_attrs %{name: "My Garden 3"}
  @invalid_attrs %{name: nil}

  defp create_garden(_) do
    garden = garden_fixture(name: "My Garden")
    %{garden: garden}
  end

  describe "Index" do
    setup [:create_garden]

    test "lists all gardens", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/gardens")

      assert html =~ "Listing Gardens"
    end

    test "saves new garden", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/gardens")

      assert index_live |> element("a", "New Garden") |> render_click() =~
               "New Garden"

      assert_patch(index_live, ~p"/gardens/new")

      assert index_live
             |> form("#garden-form", garden: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#garden-form", garden: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/gardens")

      html = render(index_live)
      assert html =~ "Garden created successfully"
    end

    test "updates garden in listing", %{conn: conn, garden: garden} do
      {:ok, index_live, _html} = live(conn, ~p"/gardens")

      assert index_live |> element("#gardens-#{garden.id} a", "Edit") |> render_click() =~
               "Edit Garden"

      assert_patch(index_live, ~p"/gardens/#{garden}/edit")

      assert index_live
             |> form("#garden-form", garden: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#garden-form", garden: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/gardens")

      html = render(index_live)
      assert html =~ "Garden updated successfully"
    end

    test "deletes garden in listing", %{conn: conn, garden: garden} do
      {:ok, index_live, _html} = live(conn, ~p"/gardens")

      assert index_live |> element("#gardens-#{garden.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#gardens-#{garden.id}")
    end
  end

  describe "Show" do
    setup [:create_garden]

    test "displays garden", %{conn: conn, garden: garden} do
      {:ok, _show_live, html} = live(conn, ~p"/gardens/#{garden}")

      assert html =~ "Show Garden"
    end

    test "updates garden within modal", %{conn: conn, garden: garden} do
      {:ok, show_live, _html} = live(conn, ~p"/gardens/#{garden}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Garden"

      assert_patch(show_live, ~p"/gardens/#{garden}/show/edit")

      assert show_live
             |> form("#garden-form", garden: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#garden-form", garden: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/gardens/#{garden}")

      html = render(show_live)
      assert html =~ "Garden updated successfully"
    end
  end

  describe "Plant" do
    setup [:create_garden]

    test "creating a new plant", %{conn: conn, garden: garden} do
      {:ok, show_live, _html} = live(conn, ~p"/gardens/#{garden}")

      assert show_live |> element("a", "Plant") |> render_click() =~ "Add Plant"

      assert_patch(show_live, ~p"/gardens/#{garden}/plant")

      assert show_live
             |> form("#plant-form",
               plant: %{name: "My Plant", qty: 3, seed_id: "-1", product_id: "-1"}
             )
             |> render_change() =~ "Seed Name"

      show_live
      |> form("#plant-form", plant: %{"name" => "My plant", "seed_id" => "-1", "product_id" => "-1"})
      |> render_change()

      show_live
      |> form("#plant-form",
        plant: %{
          name: "My New Plant",
          seed: %{"name" => "My Seed", description: "My New Seed"},
          product: %{name: "My Product", type: "growing_media"}
        }
      )
      |> render_submit()

      {:ok, _show_live, html} = live(conn, ~p"/gardens/#{garden}")
      html =~ "1 plants"
    end
  end
end
