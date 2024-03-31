defmodule VisualGardenWeb.SeedLiveTest do
  use VisualGardenWeb.ConnCase

  import Phoenix.LiveViewTest
  import VisualGarden.GardensFixtures

  @create_attrs %{name: "some name", description: "some description"}
  @update_attrs %{name: "some updated name", description: "some updated description"}
  @invalid_attrs %{name: nil, description: nil}

  defp create_seed(_) do
    seed = seed_fixture()
    %{seed: seed}
  end

  describe "Index" do
    setup [:create_seed]

    test "lists all seeds", %{conn: conn, seed: seed} do
      {:ok, _index_live, html} = live(conn, ~p"/seeds")

      assert html =~ "Listing Seeds"
      assert html =~ seed.name
    end

    test "saves new seed", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/seeds")

      assert index_live |> element("a", "New Seed") |> render_click() =~
               "New Seed"

      assert_patch(index_live, ~p"/seeds/new")

      assert index_live
             |> form("#seed-form", seed: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#seed-form", seed: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/seeds")

      html = render(index_live)
      assert html =~ "Seed created successfully"
      assert html =~ "some name"
    end

    test "updates seed in listing", %{conn: conn, seed: seed} do
      {:ok, index_live, _html} = live(conn, ~p"/seeds")

      assert index_live |> element("#seeds-#{seed.id} a", "Edit") |> render_click() =~
               "Edit Seed"

      assert_patch(index_live, ~p"/seeds/#{seed}/edit")

      assert index_live
             |> form("#seed-form", seed: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#seed-form", seed: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/seeds")

      html = render(index_live)
      assert html =~ "Seed updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes seed in listing", %{conn: conn, seed: seed} do
      {:ok, index_live, _html} = live(conn, ~p"/seeds")

      assert index_live |> element("#seeds-#{seed.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#seeds-#{seed.id}")
    end
  end

  describe "Show" do
    setup [:create_seed]

    test "displays seed", %{conn: conn, seed: seed} do
      {:ok, _show_live, html} = live(conn, ~p"/seeds/#{seed}")

      assert html =~ "Show Seed"
      assert html =~ seed.name
    end

    test "updates seed within modal", %{conn: conn, seed: seed} do
      {:ok, show_live, _html} = live(conn, ~p"/seeds/#{seed}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Seed"

      assert_patch(show_live, ~p"/seeds/#{seed}/show/edit")

      assert show_live
             |> form("#seed-form", seed: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#seed-form", seed: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/seeds/#{seed}")

      html = render(show_live)
      assert html =~ "Seed updated successfully"
      assert html =~ "some updated name"
    end
  end
end
