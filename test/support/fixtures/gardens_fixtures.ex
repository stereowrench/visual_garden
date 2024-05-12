defmodule VisualGarden.GardensFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `VisualGarden.Gardens` context.
  """
  alias VisualGarden.LibraryFixtures

  @doc """
  Generate a garden.
  """
  def garden_fixture(attrs \\ %{}, region \\ nil) do
    region =
      if region,
        do: region,
        else: LibraryFixtures.region_fixture(%{name: "garden region"})

    {:ok, garden} =
      attrs
      |> Enum.into(%{
        name: "My Garden",
        tz: "America/Chicago",
        region_id: region.id
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
    species = LibraryFixtures.species_fixture()

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
        days_to_maturation: 51,
        species_id: species.id,
        name: "some name",
        type: "seed"
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
        garden_fixture(%{name: "plant garden"})
      else
        garden
      end

    product = product_fixture(%{}, garden)

    {:ok, plant} =
      attrs
      |> Enum.into(%{
        product_id: product.id,
        qty: 1,
        row: 2,
        column: 3,
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
  def event_log_fixture(type, attrs \\ %{}) do
    product = product_fixture()

    attrs =
      attrs
      |> Enum.into(%{
        "product_id" => product.id,
        "event_time" => DateTime.utc_now(),
        "event_type" => type,
        "humidity" => 42,
        "mow_depth_in" => "120.5",
        "mowed" => true,
        "till_depth_in" => "120.5",
        "tilled" => true,
        "transfer_units" => "cuft",
        "transferred_amount" => "120.5"
      })

    {:ok, event_log} = VisualGarden.Gardens.create_event_log(type, attrs)

    event_log
  end

  @doc """
  Generate a nursery_entry.
  """
  def nursery_entry_fixture() do
    nursery_entry_fixture(garden_fixture())
  end

  def nursery_entry_fixture(garden, attrs \\ %{}) do
    {:ok, nursery_entry} =
      attrs
      |> Enum.into(%{
        sow_date: ~D[2024-05-10],
        garden_id: garden.id
      })
      |> VisualGarden.Gardens.create_nursery_entry()

    nursery_entry
  end
end
