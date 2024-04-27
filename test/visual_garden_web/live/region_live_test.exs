defmodule VisualGardenWeb.RegionLiveTest do
  use VisualGardenWeb.ConnCase

  import Phoenix.LiveViewTest
  import VisualGarden.LibraryFixtures

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  defp create_region(_) do
    region = region_fixture()
    %{region: region}
  end

  describe "Index" do
    setup [:create_region]

    test "lists all regions", %{conn: conn, region: region} do
      {:ok, _index_live, html} = live(conn, ~p"/regions")

      assert html =~ "Listing Regions"
      assert html =~ region.name
    end

    test "saves new region", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/regions")

      assert index_live |> element("a", "New Region") |> render_click() =~
               "New Region"

      assert_patch(index_live, ~p"/regions/new")

      assert index_live
             |> form("#region-form", region: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#region-form", region: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/regions")

      html = render(index_live)
      assert html =~ "Region created successfully"
      assert html =~ "some name"
    end

    test "updates region in listing", %{conn: conn, region: region} do
      {:ok, index_live, _html} = live(conn, ~p"/regions")

      assert index_live |> element("#regions-#{region.id} a", "Edit") |> render_click() =~
               "Edit Region"

      assert_patch(index_live, ~p"/regions/#{region}/edit")

      assert index_live
             |> form("#region-form", region: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#region-form", region: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/regions")

      html = render(index_live)
      assert html =~ "Region updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes region in listing", %{conn: conn, region: region} do
      {:ok, index_live, _html} = live(conn, ~p"/regions")

      assert index_live |> element("#regions-#{region.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#regions-#{region.id}")
    end
  end

  describe "Show" do
    setup [:create_region]

    test "displays region", %{conn: conn, region: region} do
      {:ok, _show_live, html} = live(conn, ~p"/regions/#{region}")

      assert html =~ "Show Region"
      assert html =~ region.name
    end

    test "updates region within modal", %{conn: conn, region: region} do
      {:ok, show_live, _html} = live(conn, ~p"/regions/#{region}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Region"

      assert_patch(show_live, ~p"/regions/#{region}/show/edit")

      assert show_live
             |> form("#region-form", region: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#region-form", region: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/regions/#{region}")

      html = render(show_live)
      assert html =~ "Region updated successfully"
      assert html =~ "some updated name"
    end
  end
end
