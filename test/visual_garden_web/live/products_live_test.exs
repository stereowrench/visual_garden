defmodule VisualGardenWeb.ProductsLiveTest do
  alias VisualGarden.Gardens
  use VisualGardenWeb.ConnCase

  import Phoenix.LiveViewTest
  import VisualGarden.GardensFixtures
  import VisualGarden.AccountsFixtures

  @create_attrs %{name: "some name", type: :growing_media}
  @update_attrs %{name: "some updated name", type: :fertilizer}
  @invalid_attrs %{name: nil, type: nil}

  defp create_products(_) do
    garden = garden_fixture(%{name: "My Garden"})
    products = product_fixture(%{}, garden)
    user = user_fixture()
    Gardens.create_garden_user(garden, user)
    %{product: products, garden: garden, user: user}
  end

  describe "Index" do
    setup [:create_products]

    test "lists all products", %{conn: conn, product: products, garden: garden, user: user} do
      conn = log_in_user(conn, user)
      {:ok, _index_live, html} = live(conn, ~p"/gardens/#{garden.id}/products")

      assert html =~ "Listing products"
      assert html =~ products.name
    end

    test "saves new products", %{conn: conn, garden: garden, user: user} do
      conn = log_in_user(conn, user)
      {:ok, index_live, _html} = live(conn, ~p"/gardens/#{garden.id}/products")

      assert index_live |> element("a", "New product") |> render_click() =~
               "New product"

      assert_patch(index_live, ~p"/gardens/#{garden.id}/products/new")

      assert index_live
             |> form("#products-form", product: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#products-form", product: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/gardens/#{garden.id}/products")

      html = render(index_live)
      assert html =~ "Products created successfully"
      assert html =~ "some name"
    end

    test "updates products in listing", %{
      conn: conn,
      product: products,
      garden: garden,
      user: user
    } do
      conn = log_in_user(conn, user)
      {:ok, index_live, _html} = live(conn, ~p"/gardens/#{garden.id}/products")

      assert index_live |> element("#product-row-#{products.id} a", "Edit") |> render_click() =~
               "Edit product"

      assert_patch(index_live, ~p"/gardens/#{garden.id}/products/#{products}/edit")

      assert index_live
             |> form("#products-form", product: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#products-form", product: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/gardens/#{garden.id}/products")

      html = render(index_live)
      assert html =~ "Products updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes products in listing", %{
      conn: conn,
      product: products,
      garden: garden,
      user: user
    } do
      conn = log_in_user(conn, user)
      {:ok, index_live, _html} = live(conn, ~p"/gardens/#{garden.id}/products")

      assert index_live |> element("#product-row-#{products.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#product-row-#{products.id}")
    end
  end

  describe "Show" do
    setup [:create_products]

    test "displays product", %{conn: conn, product: products, garden: garden, user: user} do
      conn = log_in_user(conn, user)
      {:ok, _show_live, html} = live(conn, ~p"/gardens/#{garden.id}/products/#{products}")

      assert html =~ products.name
    end

    test "updates products within modal", %{
      conn: conn,
      product: products,
      garden: garden,
      user: user
    } do
      conn = log_in_user(conn, user)
      {:ok, show_live, _html} = live(conn, ~p"/gardens/#{garden.id}/products/#{products}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit product"

      assert_patch(show_live, ~p"/gardens/#{garden.id}/products/#{products}/show/edit")

      assert show_live
             |> form("#products-form", product: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#products-form", product: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/gardens/#{garden.id}/products/#{products}")

      html = render(show_live)
      assert html =~ "Products updated successfully"
      assert html =~ "some updated name"
    end
  end
end
