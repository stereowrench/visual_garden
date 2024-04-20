defmodule VisualGarden.GardensFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `VisualGarden.Gardens` context.
  """

  @doc """
  Generate a garden.
  """
  def garden_fixture(attrs \\ %{}) do
    {:ok, garden} =
      attrs
      |> Enum.into(%{
        name: "My Garden"
      })
      |> VisualGarden.Gardens.create_garden()

    garden
  end

  @doc """
  Generate a products.
  """
  def product_fixture() do
    product_fixture(%{}, garden_fixture())
  end

  def product_fixture(attrs, garden) do
    {:ok, products} =
      attrs
      |> Enum.into(%{
        name: "some name",
        type: :growing_media
      })
      |> VisualGarden.Gardens.create_product(garden)

    products
  end

  @doc """
  Generate a seed.
  """
  def seed_fixture(attrs \\ %{}, garden \\ nil) do
    garden =
      if garden == nil do
        garden_fixture()
      else
        garden
      end

    {:ok, seed} =
      attrs
      |> Enum.into(%{
        description: "some description",
        garden_id: garden.id,
        name: "some name"
      })
      |> VisualGarden.Gardens.create_seed()

    seed
  end

  @doc """
  Generate a plant.
  """
  def plant_fixture(attrs \\ %{}, garden \\ nil) do
    garden =
      if garden == nil do
        garden_fixture()
      else
        garden
      end

    product = product_fixture(%{}, garden)

    {:ok, plant} =
      attrs
      |> Enum.into(%{
        product_id: product.id,
        qty: 1,
        name: "My plant"
      })
      |> VisualGarden.Gardens.create_plant()

    plant
  end

  @doc """
  Generate a harvest.
  """
  def harvest_fixture(attrs \\ %{}) do
    {:ok, harvest} =
      attrs
      |> Enum.into(%{
        quantity: "120.5",
        units: "cuft"
      })
      |> VisualGarden.Gardens.create_harvest()

    harvest
  end

  @doc """
  Generate a event_log.
  """
  def event_log_fixture(attrs \\ %{}) do
    {:ok, event_log} =
      attrs
      |> Enum.into(%{
        event_type: "some event_type",
        humidity: 42,
        mow_depth_in: "120.5",
        mowed: true,
        till_depth_in: "120.5",
        tilled: true,
        transfer_units: "some transfer_units",
        transferred_amount: "120.5",
        trimmed: true,
        watered: true
      })
      |> VisualGarden.Gardens.create_event_log()

    event_log
  end
end
