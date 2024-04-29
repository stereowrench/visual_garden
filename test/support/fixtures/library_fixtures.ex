defmodule VisualGarden.LibraryFixtures do
  @doc """
  Generate a species.
  """
  def species_fixture(attrs \\ %{}) do
    {:ok, species} =
      attrs
      |> Enum.into(%{
        name: "some name",
        genus: "my genus"
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
