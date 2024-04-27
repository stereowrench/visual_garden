defmodule VisualGarden.Library.TaxonomySearch do
  alias VisualGarden.Library.Species
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "taxonomy_search" do
    belongs_to :species, Species
  end
end
