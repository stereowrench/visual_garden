defmodule VisualGardenWeb.GardenLiveTest do
  alias VisualGarden.LibraryFixtures
  use VisualGardenWeb.ConnCase

  import Phoenix.LiveViewTest
  import VisualGarden.GardensFixtures
  import VisualGarden.AccountsFixtures

  @create_attrs %{name: "My Garden 2"}
  @update_attrs %{name: "My Garden 3"}
  @invalid_attrs %{name: nil}

  defp create_garden(_) do
    user = user_fixture()
    garden = garden_fixture(%{name: "My Garden", owner_id: user.id})
    %{garden: garden, user: user}
  end

  describe "unauthenticated" do
    setup [:create_garden]

    test "should return error code", %{conn: conn, garden: garden} do
      assert_raise(VisualGarden.Authorization.UnauthorizedError, fn ->
        {:ok, _, _html} = live(conn, ~p"/gardens/#{garden.id}")
      end)
    end

    test "create should send to login", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/users/log_in"}}} = live(conn, ~p"/gardens/new")
    end
  end

  describe "Index" do
    setup [:create_garden]

    test "lists all gardens", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/gardens")

      assert html =~ "Listing Gardens"
    end

    test "saves new garden", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, index_live, _html} = live(conn, ~p"/gardens")

      assert index_live |> element("a", "New Garden") |> render_click() =~
               "New Garden"

      assert_patch(index_live, ~p"/gardens/new")

      assert index_live
             |> form("#garden-form", garden: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      region = LibraryFixtures.region_fixture()

      assert index_live
             |> form("#garden-form", garden: @create_attrs)
             |> render_submit(%{garden: %{tz: "America/Chicago", region_id: region.id}})

      {path, flash} = assert_redirect(index_live)
      assert path =~ ~r/\/gardens\/\d+/
      assert unwrap_flash(flash) =~ "Garden created successfully"
    end

    test "updates garden in listing", %{conn: conn, garden: garden, user: user} do
      conn = log_in_user(conn, user)
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

    test "updates garden in listing wrong user", %{conn: conn, garden: garden} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      {:ok, index_live, _html} = live(conn, ~p"/gardens")

      assert_raise(VisualGarden.Authorization.UnauthorizedError, fn ->
        live(conn, ~p"/gardens/#{garden}/edit")
      end)
    end

    test "deletes garden in listing", %{conn: conn, garden: garden, user: user} do
      conn = log_in_user(conn, user)
      {:ok, index_live, _html} = live(conn, ~p"/gardens")

      assert index_live |> element("#gardens-#{garden.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#gardens-#{garden.id}")
    end
  end

  describe "Show" do
    setup [:create_garden]

    test "displays garden", %{conn: conn, garden: garden, user: user} do
      conn = log_in_user(conn, user)
      {:ok, _show_live, html} = live(conn, ~p"/gardens/#{garden}")

      assert html =~ "Show Garden"
    end

    test "updates garden within modal", %{conn: conn, garden: garden, user: user} do
      conn = log_in_user(conn, user)
      {:ok, show_live, _html} = live(conn, ~p"/gardens/#{garden}")

      assert show_live |> element("a", "Edit garden") |> render_click() =~
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

    test "updates garden in listing wrong user", %{conn: conn, garden: garden} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      assert_raise(VisualGarden.Authorization.UnauthorizedError, fn ->
        live(conn, ~p"/gardens/#{garden}")
      end)
    end
  end

  describe "collaborators" do
    setup [:create_garden]

    test "adding a user", %{conn: conn, garden: garden, user: owner} do
      user2 = user_fixture()
      conn = log_in_user(conn, user2)

      assert_raise(VisualGarden.Authorization.UnauthorizedError, fn ->
        live(conn, ~p"/gardens/#{garden}")
      end)

      conn = log_in_user(conn, owner)
      {:ok, show_live, _html} = live(conn, ~p"/gardens/#{garden}")

      assert show_live |> element("a", "Add collaborators") |> render_click() =~
               "Add collaborators"

      assert show_live
             |> form("#collab-form", email_schema: %{email: "f"})
             |> render_change() =~ "Not found!"

      assert show_live
             |> form("#collab-form", email_schema: %{email: user2.email})
             |> render_submit()

      conn = log_in_user(conn, user2)

      {:ok, _, _} = live(conn, ~p"/gardens/#{garden}")
    end
  end
end
