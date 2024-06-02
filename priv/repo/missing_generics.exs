alias VisualGarden.Library.Species
alias VisualGardenWeb.DisplayHelpers
alias VisualGarden.Library.LibrarySeed
alias VisualGarden.Repo
import Ecto.Query

species = Repo.all(
  from s in Species,
  preload: [:library_seeds]
)

species
|> Enum.filter(& &1.library_seeds == [])
|> Enum.map(fn sp ->
  IO.puts(DisplayHelpers.species_display_string_simple(sp))
end)
