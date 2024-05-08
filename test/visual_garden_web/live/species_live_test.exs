defmodule VisualGardenWeb.SpeciesLiveTest do
  use VisualGardenWeb.ConnCase

  import Phoenix.LiveViewTest
  import VisualGarden.LibraryFixtures

  @create_attrs %{name: "some name 2", genus: "my genus"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  defp create_species(_) do
    species = species_fixture()
    %{species: species}
  end

  describe "Index" do
    setup [:create_species]

    test "lists all species", %{conn: conn, species: species} do
      {:ok, _index_live, html} = live(conn, ~p"/species")

      assert html =~ "Listing Species"
      assert html =~ species.name
    end

    test "saves new species", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/species")

      assert index_live |> element("a", "New Species") |> render_click() =~
               "New Species"

      assert_patch(index_live, ~p"/species/new")

      assert index_live
             |> form("#species-form", species: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#species-form", species: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/species")

      html = render(index_live)
      assert html =~ "Species created successfully"
      assert html =~ "some name"
    end

    test "updates species in listing", %{conn: conn, species: species} do
      {:ok, index_live, _html} = live(conn, ~p"/species")

      assert index_live |> element("#species_collection-#{species.id} a", "Edit") |> render_click() =~
               "Edit Species"

      assert_patch(index_live, ~p"/species/#{species}/edit")

      assert index_live
             |> form("#species-form", species: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#species-form", species: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/species")

      html = render(index_live)
      assert html =~ "Species updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes species in listing", %{conn: conn, species: species} do
      {:ok, index_live, _html} = live(conn, ~p"/species")

      assert index_live |> element("#species_collection-#{species.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#species-#{species.id}")
    end
  end

  describe "Show" do
    setup [:create_species]

    test "displays species", %{conn: conn, species: species} do
      {:ok, _show_live, html} = live(conn, ~p"/species/#{species}")

      assert html =~ "Show Species"
      assert html =~ species.name
    end

    test "updates species within modal", %{conn: conn, species: species} do
      {:ok, show_live, _html} = live(conn, ~p"/species/#{species}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Species"

      assert_patch(show_live, ~p"/species/#{species}/show/edit")

      assert show_live
             |> form("#species-form", species: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#species-form", species: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/species/#{species}")

      html = render(show_live)
      assert html =~ "Species updated successfully"
      assert html =~ "some updated name"
    end
  end
end
