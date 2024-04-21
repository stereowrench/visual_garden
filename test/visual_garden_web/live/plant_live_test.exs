defmodule VisualGardenWeb.PlantLiveTest do
  use VisualGardenWeb.ConnCase

  import Phoenix.LiveViewTest
  import VisualGarden.GardensFixtures

  @create_attrs %{name: "my plant", qty: 1}
  @update_attrs %{name: "my plant 2"}
  @invalid_attrs %{name: nil}

  defp create_plant(_) do
    garden = garden_fixture()
    product = product_fixture(%{}, garden)
    plant = plant_fixture(%{product_id: product.id}, garden)
    %{plant: plant, product: product, garden: garden}
  end

  describe "Index" do
    setup [:create_plant]

    test "lists all plants", %{conn: conn, garden: garden} do
      {:ok, _index_live, html} = live(conn, ~p"/gardens/#{garden.id}/plants")

      assert html =~ "Listing Plants"
    end

    test "lists all plants under product", %{conn: conn, garden: garden, product: product} do
      {:ok, _index_live, html} = live(conn, ~p"/gardens/#{garden.id}/products/#{product.id}/plants")

      assert html =~ "Listing Plants"
    end

    test "saves new plant from garden view", %{conn: conn, garden: garden, product: product} do
      {:ok, index_live, _html} = live(conn, ~p"/gardens/#{garden.id}")

      assert index_live |> element("a", "Plant a plant") |> render_click() =~
               "Add Plant"

      assert_patch(index_live, ~p"/gardens/#{garden.id}/plant")

      assert index_live
             |> form("#plant-form", plant: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#plant-form", plant: Map.merge(@create_attrs, %{product_id: product.id}))
             |> render_submit()

      assert_patch(index_live, ~p"/gardens/#{garden.id}")

      html = render(index_live)
      assert html =~ "Plant created successfully"
    end

    test "saves new plant from plants view", %{conn: conn, garden: garden, product: product} do
      {:ok, index_live, _html} = live(conn, ~p"/gardens/#{garden.id}/plants")

      assert index_live |> element("a", "New Plant") |> render_click() =~
               "New Plant"

      assert_patch(index_live, ~p"/gardens/#{garden.id}/plants/new")

      assert index_live
             |> form("#plant-form", plant: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#plant-form", plant: Map.merge(@create_attrs, %{product_id: product.id}))
             |> render_submit()

      assert_patch(index_live, ~p"/gardens/#{garden.id}/plants")

      html = render(index_live)
      assert html =~ "Plant created successfully"
    end

    test "updates plant in listing", %{conn: conn, plant: plant, garden: garden, product: product} do
      {:ok, index_live, _html} = live(conn, ~p"/gardens/#{garden.id}/plants")

      assert index_live |> element("#plants-#{plant.id} a", "Edit") |> render_click() =~
               "Edit Plant"

      assert_patch(index_live, ~p"/gardens/#{garden.id}/products/#{product.id}/plants/#{plant}/edit")

      assert index_live
             |> form("#plant-form", plant: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#plant-form", plant: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/gardens/#{garden.id}/plants")

      html = render(index_live)
      assert html =~ "Plant updated successfully"
    end

    test "deletes plant in listing", %{conn: conn, plant: plant, garden: garden} do
      {:ok, index_live, _html} = live(conn, ~p"/gardens/#{garden.id}/plants")

      assert index_live |> element("#plants-#{plant.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#plants-#{plant.id}")
    end
  end

  describe "Show" do
    setup [:create_plant]

    test "displays plant", %{conn: conn, plant: plant, garden: garden, product: product} do
      {:ok, _show_live, html} = live(conn, ~p"/gardens/#{garden.id}/products/#{product.id}/plants/#{plant}")

      assert html =~ "Show Plant"
    end

    test "updates plant within modal", %{conn: conn, plant: plant, garden: garden, product: product} do
      {:ok, show_live, _html} = live(conn, ~p"/gardens/#{garden.id}/products/#{product.id}/plants/#{plant}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Plant"

      assert_patch(show_live, ~p"/gardens/#{garden.id}/products/#{product.id}/plants/#{plant}/show/edit")

      assert show_live
             |> form("#plant-form", plant: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#plant-form", plant: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/gardens/#{garden.id}/products/#{product.id}/plants/#{plant}")

      html = render(show_live)
      assert html =~ "Plant updated successfully"
    end
  end
end
