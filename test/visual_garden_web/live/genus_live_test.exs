defmodule VisualGardenWeb.GenusLiveTest do
  use VisualGardenWeb.ConnCase

  import Phoenix.LiveViewTest
  import VisualGarden.LibraryFixtures

  @create_attrs %{name: "some unique name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  defp create_genus(_) do
    genus = genus_fixture()
    %{genus: genus}
  end

  describe "Index" do
    setup [:create_genus]

    test "lists all genera", %{conn: conn, genus: genus} do
      {:ok, _index_live, html} = live(conn, ~p"/genera")

      assert html =~ "Listing Genera"
      assert html =~ genus.name
    end

    test "saves new genus", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/genera")

      assert index_live |> element("a", "New Genus") |> render_click() =~
               "New Genus"

      assert_patch(index_live, ~p"/genera/new")

      assert index_live
             |> form("#genus-form", genus: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#genus-form", genus: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/genera")

      html = render(index_live)
      assert html =~ "Genus created successfully"
      assert html =~ "some name"
    end

    test "updates genus in listing", %{conn: conn, genus: genus} do
      {:ok, index_live, _html} = live(conn, ~p"/genera")

      assert index_live |> element("#genera-#{genus.id} a", "Edit") |> render_click() =~
               "Edit Genus"

      assert_patch(index_live, ~p"/genera/#{genus}/edit")

      assert index_live
             |> form("#genus-form", genus: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#genus-form", genus: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/genera")

      html = render(index_live)
      assert html =~ "Genus updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes genus in listing", %{conn: conn, genus: genus} do
      {:ok, index_live, _html} = live(conn, ~p"/genera")

      assert index_live |> element("#genera-#{genus.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#genera-#{genus.id}")
    end
  end

  describe "Show" do
    setup [:create_genus]

    test "displays genus", %{conn: conn, genus: genus} do
      {:ok, _show_live, html} = live(conn, ~p"/genera/#{genus}")

      assert html =~ "Show Genus"
      assert html =~ genus.name
    end

    test "updates genus within modal", %{conn: conn, genus: genus} do
      {:ok, show_live, _html} = live(conn, ~p"/genera/#{genus}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Genus"

      assert_patch(show_live, ~p"/genera/#{genus}/show/edit")

      assert show_live
             |> form("#genus-form", genus: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#genus-form", genus: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/genera/#{genus}")

      html = render(show_live)
      assert html =~ "Genus updated successfully"
      assert html =~ "some updated name"
    end
  end
end
