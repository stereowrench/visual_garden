# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     VisualGarden.Repo.insert!(%VisualGarden.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias VisualGarden.Planner
alias VisualGarden.Repo
alias VisualGarden.Library
alias VisualGarden.Library.{LibrarySeed, Schedule, Species, Region}
import Ecto.Query

Path.join([__DIR__, "./seed_data/Species.csv"])
|> File.stream!()
|> CSV.decode!(headers: true)
|> Stream.map(fn
  %{
    "UUID" => uuid,
    "Common Name" => name,
    "Genus" => genus,
    "Species" => species,
    "Variety" => variety,
    "Season" => season
  } ->
    case Repo.one(from sp in Species, where: sp.uuid == ^uuid) do
      nil ->
        {:ok, _} =
          Library.create_species(%{
            name: String.trim(species),
            genus: String.trim(genus),
            variant: String.trim(variety),
            season: String.trim(season),
            uuid: uuid,
            common_name: String.trim(name)
          })

      sp ->
        Species.changeset(
          sp,
          %{
            name: String.trim(species),
            genus: String.trim(genus),
            variant: String.trim(variety),
            season: String.trim(season),
            uuid: uuid,
            common_name: String.trim(name)
          }
        )
        |> Repo.update!()
    end
end)
|> Stream.run()

regions = ["South Florida"]

defmodule Query do
  import Ecto.Query

  def add_var_query(q, nil) do
    from a in q, where: is_nil(a.variant)
  end

  def add_var_query(q, var) do
    from a in q, where: a.variant == ^var
  end

  def add_cultivar_query(q, nil) do
    from a in q, where: is_nil(a.cultivar)
  end

  def add_cultivar_query(q, var) do
    from a in q, where: a.cultivar == ^var
  end

  def add_season_query(q, nil) do
    from a in q, where: is_nil(a.season)
  end

  def add_season_query(q, var) do
    from a in q, where: a.season == ^var
  end
end

for region_name <- regions do
  region =
    case Repo.one(from r in Region, where: r.name == ^region_name) do
      nil ->
        {:ok, r} = Library.create_region(%{name: region_name})

      r ->
        r
    end

  Path.join([__DIR__, "./seed_data/Region - #{region.name}.csv"])
  |> File.stream!()
  |> CSV.decode!(headers: true)
  |> Stream.map(fn
    %{
      "Name" => name,
      "Start Month" => sm,
      "Start Day" => sd,
      "End Month" => em,
      "End Day" => ed,
      "Type" => type,
      "Min Weeks" => min_w,
      "Max Weeks" => max_w,
      "Genus" => genus,
      "Species" => species,
      "Variety" => var,
      "Cultivar" => cultivar,
      "Season" => season
    } ->
      var = if var == "", do: nil, else: String.trim(var)
      cultivar = if cultivar == "", do: nil, else: String.trim(cultivar)
      season = if season == "", do: nil, else: String.trim(season)
      genus = String.trim(genus)
      species = String.trim(species)

      species =
        Repo.one!(
          from(s in Species,
            where: s.genus == ^genus and s.name == ^species
          )
          |> Query.add_var_query(var)
          |> Query.add_cultivar_query(cultivar)
          |> Query.add_season_query(season)
        )

      attrs = %{
        label: name,
        start_month: sm,
        start_day: sd,
        end_month: em,
        end_day: ed,
        nursery_lead_weeks_min: min_w,
        nursery_lead_weeks_max: max_w,
        plantable_types: String.split(type, ","),
        region_id: region.id,
        species_id: species.id
      }

      case(
        Repo.one(
          from s in Schedule,
            where: s.label == ^name and s.species_id == ^species.id and s.region_id == ^region.id
        )
      ) do
        nil ->
          {:ok, _schedule} = Library.create_schedule(attrs)

        s ->
          {:ok, _} = Library.update_schedule(s, attrs)
      end
  end)
  |> Stream.run()
end
