defmodule VisualGardenWeb.EventLogLiveTest do
  use VisualGardenWeb.ConnCase

  import Phoenix.LiveViewTest
  import VisualGarden.GardensFixtures

  @create_attrs %{event_type: "some event_type", watered: true, humidity: 42, mowed: true, mow_depth_in: "120.5", tilled: true, till_depth_in: "120.5", transferred_amount: "120.5", trimmed: true, transfer_units: "some transfer_units"}
  @update_attrs %{event_type: "some updated event_type", watered: false, humidity: 43, mowed: false, mow_depth_in: "456.7", tilled: false, till_depth_in: "456.7", transferred_amount: "456.7", trimmed: false, transfer_units: "some updated transfer_units"}
  @invalid_attrs %{event_type: nil, watered: false, humidity: nil, mowed: false, mow_depth_in: nil, tilled: false, till_depth_in: nil, transferred_amount: nil, trimmed: false, transfer_units: nil}

  defp create_event_log(_) do
    event_log = event_log_fixture()
    %{event_log: event_log}
  end

  describe "Index" do
    setup [:create_event_log]

    test "lists all event_logs", %{conn: conn, event_log: event_log} do
      {:ok, _index_live, html} = live(conn, ~p"/event_logs")

      assert html =~ "Listing Event logs"
      assert html =~ event_log.event_type
    end

    test "saves new event_log", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/event_logs")

      assert index_live |> element("a", "New Event log") |> render_click() =~
               "New Event log"

      assert_patch(index_live, ~p"/event_logs/new")

      assert index_live
             |> form("#event_log-form", event_log: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#event_log-form", event_log: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/event_logs")

      html = render(index_live)
      assert html =~ "Event log created successfully"
      assert html =~ "some event_type"
    end

    test "updates event_log in listing", %{conn: conn, event_log: event_log} do
      {:ok, index_live, _html} = live(conn, ~p"/event_logs")

      assert index_live |> element("#event_logs-#{event_log.id} a", "Edit") |> render_click() =~
               "Edit Event log"

      assert_patch(index_live, ~p"/event_logs/#{event_log}/edit")

      assert index_live
             |> form("#event_log-form", event_log: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#event_log-form", event_log: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/event_logs")

      html = render(index_live)
      assert html =~ "Event log updated successfully"
      assert html =~ "some updated event_type"
    end

    test "deletes event_log in listing", %{conn: conn, event_log: event_log} do
      {:ok, index_live, _html} = live(conn, ~p"/event_logs")

      assert index_live |> element("#event_logs-#{event_log.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#event_logs-#{event_log.id}")
    end
  end

  describe "Show" do
    setup [:create_event_log]

    test "displays event_log", %{conn: conn, event_log: event_log} do
      {:ok, _show_live, html} = live(conn, ~p"/event_logs/#{event_log}")

      assert html =~ "Show Event log"
      assert html =~ event_log.event_type
    end

    test "updates event_log within modal", %{conn: conn, event_log: event_log} do
      {:ok, show_live, _html} = live(conn, ~p"/event_logs/#{event_log}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Event log"

      assert_patch(show_live, ~p"/event_logs/#{event_log}/show/edit")

      assert show_live
             |> form("#event_log-form", event_log: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#event_log-form", event_log: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/event_logs/#{event_log}")

      html = render(show_live)
      assert html =~ "Event log updated successfully"
      assert html =~ "some updated event_type"
    end
  end
end
