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

      })
      |> VisualGarden.Gardens.create_garden()

    garden
  end

  @doc """
  Generate a products.
  """
  def products_fixture(attrs \\ %{}) do
    {:ok, products} =
      attrs
      |> Enum.into(%{
        name: "some name",
        type: :growing_media
      })
      |> VisualGarden.Gardens.create_products()

    products
  end
end
