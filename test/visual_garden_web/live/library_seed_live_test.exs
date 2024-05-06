defmodule VisualGardenWeb.LibrarySeedLiveTest do
  use VisualGardenWeb.ConnCase

  import Phoenix.LiveViewTest
  import VisualGarden.LibraryFixtures

  @create_attrs %{type: :transplant, days_to_maturation: 42, manufacturer: "some manufacturer"}
  @update_attrs %{type: :seed, days_to_maturation: 43, manufacturer: "some updated manufacturer"}
  @invalid_attrs %{type: nil, days_to_maturation: nil, manufacturer: nil}

  defp create_library_seed(_) do
    library_seed = library_seed_fixture()
    %{library_seed: library_seed}
  end

  describe "Index" do
    setup [:create_library_seed]

    test "lists all library_seeds", %{conn: conn, library_seed: library_seed} do
      {:ok, _index_live, html} = live(conn, ~p"/library_seeds")

      assert html =~ "Listing Library seeds"
      assert html =~ library_seed.manufacturer
    end

    test "saves new library_seed", %{conn: conn} do
      species = species_fixture()
      {:ok, index_live, _html} = live(conn, ~p"/library_seeds")

      assert index_live |> element("a", "New Library seed") |> render_click() =~
               "New Library seed"

      assert_patch(index_live, ~p"/library_seeds/new")

      assert index_live
             |> form("#library_seed-form", library_seed: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#library_seed-form", library_seed: @create_attrs)
             |> render_submit(%{library_seed: %{species_id: species.id}})

      assert_patch(index_live, ~p"/library_seeds")

      html = render(index_live)
      assert html =~ "Library seed created successfully"
      assert html =~ "some manufacturer"
    end

    test "updates library_seed in listing", %{conn: conn, library_seed: library_seed} do
      {:ok, index_live, _html} = live(conn, ~p"/library_seeds")

      assert index_live |> element("#library_seeds-#{library_seed.id} a", "Edit") |> render_click() =~
               "Edit Library seed"

      assert_patch(index_live, ~p"/library_seeds/#{library_seed}/edit")

      assert index_live
             |> form("#library_seed-form", library_seed: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#library_seed-form", library_seed: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/library_seeds")

      html = render(index_live)
      assert html =~ "Library seed updated successfully"
      assert html =~ "some updated manufacturer"
    end

    test "deletes library_seed in listing", %{conn: conn, library_seed: library_seed} do
      {:ok, index_live, _html} = live(conn, ~p"/library_seeds")

      assert index_live |> element("#library_seeds-#{library_seed.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#library_seeds-#{library_seed.id}")
    end
  end

  describe "Show" do
    setup [:create_library_seed]

    test "displays library_seed", %{conn: conn, library_seed: library_seed} do
      {:ok, _show_live, html} = live(conn, ~p"/library_seeds/#{library_seed}")

      assert html =~ "Show Library seed"
      assert html =~ library_seed.manufacturer
    end

    test "updates library_seed within modal", %{conn: conn, library_seed: library_seed} do
      {:ok, show_live, _html} = live(conn, ~p"/library_seeds/#{library_seed}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Library seed"

      assert_patch(show_live, ~p"/library_seeds/#{library_seed}/show/edit")

      assert show_live
             |> form("#library_seed-form", library_seed: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#library_seed-form", library_seed: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/library_seeds/#{library_seed}")

      html = render(show_live)
      assert html =~ "Library seed updated successfully"
      assert html =~ "some updated manufacturer"
    end
  end
end
