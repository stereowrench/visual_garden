defmodule VisualGardenWeb.HarvestLiveTest do
  use VisualGardenWeb.ConnCase

  import Phoenix.LiveViewTest
  import VisualGarden.GardensFixtures

  @create_attrs %{quantity: "120.5", units: "some units"}
  @update_attrs %{quantity: "456.7", units: "some updated units"}
  @invalid_attrs %{quantity: nil, units: nil}

  defp create_harvest(_) do
    harvest = harvest_fixture()
    %{harvest: harvest}
  end

  describe "Index" do
    setup [:create_harvest]

    test "lists all harvests", %{conn: conn, harvest: harvest} do
      {:ok, _index_live, html} = live(conn, ~p"/harvests")

      assert html =~ "Listing Harvests"
      assert html =~ harvest.units
    end

    test "saves new harvest", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/harvests")

      assert index_live |> element("a", "New Harvest") |> render_click() =~
               "New Harvest"

      assert_patch(index_live, ~p"/harvests/new")

      assert index_live
             |> form("#harvest-form", harvest: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#harvest-form", harvest: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/harvests")

      html = render(index_live)
      assert html =~ "Harvest created successfully"
      assert html =~ "some units"
    end

    test "updates harvest in listing", %{conn: conn, harvest: harvest} do
      {:ok, index_live, _html} = live(conn, ~p"/harvests")

      assert index_live |> element("#harvests-#{harvest.id} a", "Edit") |> render_click() =~
               "Edit Harvest"

      assert_patch(index_live, ~p"/harvests/#{harvest}/edit")

      assert index_live
             |> form("#harvest-form", harvest: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#harvest-form", harvest: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/harvests")

      html = render(index_live)
      assert html =~ "Harvest updated successfully"
      assert html =~ "some updated units"
    end

    test "deletes harvest in listing", %{conn: conn, harvest: harvest} do
      {:ok, index_live, _html} = live(conn, ~p"/harvests")

      assert index_live |> element("#harvests-#{harvest.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#harvests-#{harvest.id}")
    end
  end

  describe "Show" do
    setup [:create_harvest]

    test "displays harvest", %{conn: conn, harvest: harvest} do
      {:ok, _show_live, html} = live(conn, ~p"/harvests/#{harvest}")

      assert html =~ "Show Harvest"
      assert html =~ harvest.units
    end

    test "updates harvest within modal", %{conn: conn, harvest: harvest} do
      {:ok, show_live, _html} = live(conn, ~p"/harvests/#{harvest}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Harvest"

      assert_patch(show_live, ~p"/harvests/#{harvest}/show/edit")

      assert show_live
             |> form("#harvest-form", harvest: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#harvest-form", harvest: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/harvests/#{harvest}")

      html = render(show_live)
      assert html =~ "Harvest updated successfully"
      assert html =~ "some updated units"
    end
  end
end
