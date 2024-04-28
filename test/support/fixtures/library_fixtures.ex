defmodule VisualGarden.LibraryFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `VisualGarden.Library` context.
  """

  @doc """
  Generate a genus.
  """
  def genus_fixture(attrs \\ %{}) do
    {:ok, genus} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> VisualGarden.Library.create_genus()

    genus
  end

  @doc """
  Generate a species.
  """
  def species_fixture(attrs \\ %{}) do
    genus = genus_fixture()
    {:ok, species} =
      attrs
      |> Enum.into(%{
        name: "some name",
        genus_id: genus.id
      })
      |> VisualGarden.Library.create_species()

    species
  end

  @doc """
  Generate a region.
  """
  def region_fixture(attrs \\ %{}) do
    {:ok, region} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> VisualGarden.Library.create_region()

    region
  end

  @doc """
  Generate a schedule.
  """
  def schedule_fixture(attrs \\ %{}) do
    {:ok, schedule} =
      attrs
      |> Enum.into(%{
        end_day: 42,
        end_month: 42,
        end_month_adjusted: 42,
        start_day: 42,
        start_month: 42
      })
      |> VisualGarden.Library.create_schedule()

    schedule
  end
end
