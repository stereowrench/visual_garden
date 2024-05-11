defmodule VisualGardenWeb.NurseryEntryLiveTest do
  use VisualGardenWeb.ConnCase

  import Phoenix.LiveViewTest
  import VisualGarden.GardensFixtures

  @create_attrs %{sow_date: "2024-05-10"}
  @update_attrs %{sow_date: "2024-05-11"}
  @invalid_attrs %{sow_date: nil}

  defp create_nursery_entry(_) do
    nursery_entry = nursery_entry_fixture()
    %{nursery_entry: nursery_entry}
  end

  describe "Index" do
    setup [:create_nursery_entry]

    test "lists all nursery_entries", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/nursery_entries")

      assert html =~ "Listing Nursery entries"
    end

    test "saves new nursery_entry", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/nursery_entries")

      assert index_live |> element("a", "New Nursery entry") |> render_click() =~
               "New Nursery entry"

      assert_patch(index_live, ~p"/nursery_entries/new")

      assert index_live
             |> form("#nursery_entry-form", nursery_entry: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#nursery_entry-form", nursery_entry: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/nursery_entries")

      html = render(index_live)
      assert html =~ "Nursery entry created successfully"
    end

    test "updates nursery_entry in listing", %{conn: conn, nursery_entry: nursery_entry} do
      {:ok, index_live, _html} = live(conn, ~p"/nursery_entries")

      assert index_live |> element("#nursery_entries-#{nursery_entry.id} a", "Edit") |> render_click() =~
               "Edit Nursery entry"

      assert_patch(index_live, ~p"/nursery_entries/#{nursery_entry}/edit")

      assert index_live
             |> form("#nursery_entry-form", nursery_entry: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#nursery_entry-form", nursery_entry: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/nursery_entries")

      html = render(index_live)
      assert html =~ "Nursery entry updated successfully"
    end

    test "deletes nursery_entry in listing", %{conn: conn, nursery_entry: nursery_entry} do
      {:ok, index_live, _html} = live(conn, ~p"/nursery_entries")

      assert index_live |> element("#nursery_entries-#{nursery_entry.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#nursery_entries-#{nursery_entry.id}")
    end
  end

  describe "Show" do
    setup [:create_nursery_entry]

    test "displays nursery_entry", %{conn: conn, nursery_entry: nursery_entry} do
      {:ok, _show_live, html} = live(conn, ~p"/nursery_entries/#{nursery_entry}")

      assert html =~ "Show Nursery entry"
    end

    test "updates nursery_entry within modal", %{conn: conn, nursery_entry: nursery_entry} do
      {:ok, show_live, _html} = live(conn, ~p"/nursery_entries/#{nursery_entry}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Nursery entry"

      assert_patch(show_live, ~p"/nursery_entries/#{nursery_entry}/show/edit")

      assert show_live
             |> form("#nursery_entry-form", nursery_entry: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#nursery_entry-form", nursery_entry: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/nursery_entries/#{nursery_entry}")

      html = render(show_live)
      assert html =~ "Nursery entry updated successfully"
    end
  end
end
