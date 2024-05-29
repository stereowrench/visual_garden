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
            name: species,
            genus: genus,
            variant: variety,
            season: season,
            uuid: uuid,
            common_name: name
          })

      sp ->
        Species.changeset(
          sp,
          %{name: species, genus: genus, variant: variety, season: season, common_name: name}
        )
        |> Repo.update!()
    end
end)
|> Stream.run()
