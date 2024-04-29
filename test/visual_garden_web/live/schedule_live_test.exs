defmodule VisualGardenWeb.ScheduleLiveTest do
  use VisualGardenWeb.ConnCase

  import Phoenix.LiveViewTest
  import VisualGarden.LibraryFixtures

  @create_attrs %{start_month: 42, start_day: 42, end_month: 42, end_day: 42}
  @update_attrs %{start_month: 43, start_day: 43, end_month: 43, end_day: 42}
  @invalid_attrs %{start_month: nil, start_day: nil, end_month: nil, end_day: nil}

  defp create_schedule(_) do
    region = region_fixture(%{name: "my region"})
    species = species_fixture()
    schedule = schedule_fixture(%{region_id: region.id, species_id: species.id})
    %{schedule: schedule}
  end

  describe "Index" do
    setup [:create_schedule]

    test "lists all schedules", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/schedules")

      assert html =~ "Listing Schedules"
    end

    test "saves new schedule", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/schedules")

      assert index_live |> element("a", "New Schedule") |> render_click() =~
               "New Schedule"

      assert_patch(index_live, ~p"/schedules/new")

      assert index_live
             |> form("#schedule-form", schedule: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      region = region_fixture(%{name: "my new name"})
      species = species_fixture(%{name: "my new region"})

      assert index_live
             |> form("#schedule-form",
               schedule: @create_attrs
             )
             |> render_submit(%{schedule: %{region_id: region.id, species_id: species.id}})

      assert_patch(index_live, ~p"/schedules")

      html = render(index_live)
      assert html =~ "Schedule created successfully"
    end

    test "updates schedule in listing", %{conn: conn, schedule: schedule} do
      {:ok, index_live, _html} = live(conn, ~p"/schedules")

      assert index_live |> element("#schedules-#{schedule.id} a", "Edit") |> render_click() =~
               "Edit Schedule"

      assert_patch(index_live, ~p"/schedules/#{schedule}/edit")

      assert index_live
             |> form("#schedule-form", schedule: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#schedule-form", schedule: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/schedules")

      html = render(index_live)
      assert html =~ "Schedule updated successfully"
    end

    test "deletes schedule in listing", %{conn: conn, schedule: schedule} do
      {:ok, index_live, _html} = live(conn, ~p"/schedules")

      assert index_live |> element("#schedules-#{schedule.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#schedules-#{schedule.id}")
    end
  end

  describe "Show" do
    setup [:create_schedule]

    test "displays schedule", %{conn: conn, schedule: schedule} do
      {:ok, _show_live, html} = live(conn, ~p"/schedules/#{schedule}")

      assert html =~ "Show Schedule"
    end

    test "updates schedule within modal", %{conn: conn, schedule: schedule} do
      {:ok, show_live, _html} = live(conn, ~p"/schedules/#{schedule}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Schedule"

      assert_patch(show_live, ~p"/schedules/#{schedule}/show/edit")

      assert show_live
             |> form("#schedule-form", schedule: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#schedule-form", schedule: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/schedules/#{schedule}")

      html = render(show_live)
      assert html =~ "Schedule updated successfully"
    end
  end
end
