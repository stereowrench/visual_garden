defmodule VisualGardenWeb.SeedLiveTest do
  alias VisualGarden.Gardens
  alias VisualGarden.LibraryFixtures
  use VisualGardenWeb.ConnCase

  import Phoenix.LiveViewTest
  import VisualGarden.GardensFixtures
  import VisualGarden.AccountsFixtures

  @create_attrs %{
    name: "some name 3",
    description: "some description",
    days_to_maturation: 30,
    type: "seed"
  }
  @update_attrs %{name: "some updated name 4", description: "some updated description"}
  @invalid_attrs %{name: nil, description: nil}

  defp create_seed(_) do
    region = LibraryFixtures.region_fixture()
    garden = garden_fixture(%{name: "My Garden"}, region)
    seed = seed_fixture(%{garden_id: garden.id, name: "My seed", description: "foo bar"})
    user = user_fixture()
    Gardens.create_garden_user(garden, user)
    %{garden: garden, seed: seed, user: user}
  end

  describe "Index" do
    setup [:create_seed]

    test "lists all seeds", %{conn: conn, seed: seed, garden: garden, user: user} do
      conn = log_in_user(conn, user)
      {:ok, _index_live, html} = live(conn, ~p"/gardens/#{garden.id}/seeds")

      assert html =~ "Listing Seeds"
      assert html =~ seed.name
    end

    test "saves new seed", %{conn: conn, garden: garden, user: user} do
      conn = log_in_user(conn, user)
      species = LibraryFixtures.species_fixture(%{name: "seed live"})
      {:ok, index_live, _html} = live(conn, ~p"/gardens/#{garden.id}/seeds")

      assert index_live |> element("a", "New Seed") |> render_click() =~
               "New Seed"

      assert_patch(index_live, ~p"/gardens/#{garden.id}/seeds/new")

      assert index_live
             |> form("#seed-form", seed: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#seed-form", seed: @create_attrs)
             |> render_submit(%{seed: %{species_id: species.id}})

      assert_patch(index_live, ~p"/gardens/#{garden.id}/seeds")

      html = render(index_live)
      assert html =~ "Seed created successfully"
      assert html =~ "some name"
    end

    test "updates seed in listing", %{conn: conn, seed: seed, garden: garden, user: user} do
      conn = log_in_user(conn, user)
      {:ok, index_live, _html} = live(conn, ~p"/gardens/#{garden.id}/seeds")

      assert index_live |> element("#seeds-#{seed.id} a", "Edit") |> render_click() =~
               "Edit Plantable"

      assert_patch(index_live, ~p"/gardens/#{garden.id}/seeds/#{seed}/edit")

      assert index_live
             |> form("#seed-form", seed: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#seed-form", seed: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/gardens/#{garden.id}/seeds")

      html = render(index_live)
      assert html =~ "Seed updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes seed in listing", %{conn: conn, seed: seed, garden: garden, user: user} do
      conn = log_in_user(conn, user)
      {:ok, index_live, _html} = live(conn, ~p"/gardens/#{garden.id}/seeds")

      assert index_live |> element("#seeds-#{seed.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#seeds-#{seed.id}")
    end
  end

  describe "Show" do
    setup [:create_seed]

    test "displays seed", %{conn: conn, seed: seed, garden: garden, user: user} do
      conn = log_in_user(conn, user)
      {:ok, _show_live, html} = live(conn, ~p"/gardens/#{garden.id}/seeds/#{seed}")

      assert html =~ "Show Plantable"
      assert html =~ seed.name
    end

    test "updates seed within modal", %{conn: conn, seed: seed, garden: garden, user: user} do
      conn = log_in_user(conn, user)
      {:ok, show_live, _html} = live(conn, ~p"/gardens/#{garden.id}/seeds/#{seed}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Plantable"

      assert_patch(show_live, ~p"/gardens/#{garden.id}/seeds/#{seed}/show/edit")

      assert show_live
             |> form("#seed-form", seed: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#seed-form", seed: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/gardens/#{garden.id}/seeds/#{seed}")

      html = render(show_live)
      assert html =~ "Seed updated successfully"
      assert html =~ "some updated name"
    end
  end
end
