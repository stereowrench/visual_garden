defmodule VisualGardenWeb.NurseryEntryLiveTest do
  use VisualGardenWeb.ConnCase

  import Phoenix.LiveViewTest
  import VisualGarden.GardensFixtures

  @create_attrs %{sow_date: "2024-05-10"}
  @update_attrs %{sow_date: "2024-05-11"}
  @invalid_attrs %{sow_date: nil}

  defp create_nursery_entry(_) do
    garden = garden_fixture()
    nursery_entry = nursery_entry_fixture(garden)
    %{nursery_entry: nursery_entry, garden: garden}
  end

  describe "Index" do
    setup [:create_nursery_entry]

    test "lists all nursery_entries", %{conn: conn, garden: garden} do
      {:ok, _index_live, html} = live(conn, ~p"/gardens/#{garden.id}/nursery_entries")

      assert html =~ "Listing Nursery entries"
    end

    test "deletes nursery_entry in listing", %{
      conn: conn,
      nursery_entry: nursery_entry,
      garden: garden
    } do
      {:ok, index_live, _html} = live(conn, ~p"/gardens/#{garden.id}/nursery_entries")

      assert index_live
             |> element("#nursery_entries-#{nursery_entry.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#nursery_entries-#{nursery_entry.id}")
    end
  end

  describe "Show" do
    setup [:create_nursery_entry]

    test "displays nursery_entry", %{conn: conn, nursery_entry: nursery_entry, garden: garden} do
      {:ok, _show_live, html} =
        live(conn, ~p"/gardens/#{garden.id}/nursery_entries/#{nursery_entry}")

      assert html =~ "Show Nursery entry"
    end
  end
end
