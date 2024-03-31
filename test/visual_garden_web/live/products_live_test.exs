defmodule VisualGardenWeb.ProductsLiveTest do
  use VisualGardenWeb.ConnCase

  import Phoenix.LiveViewTest
  import VisualGarden.GardensFixtures

  @create_attrs %{name: "some name", type: :growing_media}
  @update_attrs %{name: "some updated name", type: :fertilizer}
  @invalid_attrs %{name: nil, type: nil}

  defp create_products(_) do
    products = products_fixture()
    %{products: products}
  end

  describe "Index" do
    setup [:create_products]

    test "lists all products", %{conn: conn, products: products} do
      {:ok, _index_live, html} = live(conn, ~p"/products")

      assert html =~ "Listing Products"
      assert html =~ products.name
    end

    test "saves new products", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/products")

      assert index_live |> element("a", "New Products") |> render_click() =~
               "New Products"

      assert_patch(index_live, ~p"/products/new")

      assert index_live
             |> form("#products-form", products: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#products-form", products: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/products")

      html = render(index_live)
      assert html =~ "Products created successfully"
      assert html =~ "some name"
    end

    test "updates products in listing", %{conn: conn, products: products} do
      {:ok, index_live, _html} = live(conn, ~p"/products")

      assert index_live |> element("#products-#{products.id} a", "Edit") |> render_click() =~
               "Edit Products"

      assert_patch(index_live, ~p"/products/#{products}/edit")

      assert index_live
             |> form("#products-form", products: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#products-form", products: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/products")

      html = render(index_live)
      assert html =~ "Products updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes products in listing", %{conn: conn, products: products} do
      {:ok, index_live, _html} = live(conn, ~p"/products")

      assert index_live |> element("#products-#{products.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#products-#{products.id}")
    end
  end

  describe "Show" do
    setup [:create_products]

    test "displays products", %{conn: conn, products: products} do
      {:ok, _show_live, html} = live(conn, ~p"/products/#{products}")

      assert html =~ "Show Products"
      assert html =~ products.name
    end

    test "updates products within modal", %{conn: conn, products: products} do
      {:ok, show_live, _html} = live(conn, ~p"/products/#{products}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Products"

      assert_patch(show_live, ~p"/products/#{products}/show/edit")

      assert show_live
             |> form("#products-form", products: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#products-form", products: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/products/#{products}")

      html = render(show_live)
      assert html =~ "Products updated successfully"
      assert html =~ "some updated name"
    end
  end
end
