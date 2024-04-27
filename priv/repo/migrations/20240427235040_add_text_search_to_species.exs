defmodule VisualGarden.Repo.Migrations.AddTextSearchToSpecies do
  use Ecto.Migration

  def up do
    execute """
      ALTER TABLE taxonomy_search
        ADD COLUMN searchable tsvector
        GENERATED ALWAYS AS (
          setweight(to_tsvector('english', coalesce(genus, '')), 'A') ||
          setweight(to_tsvector('english', coalesce(species, '')), 'A') ||
          setweight(to_tsvector('english', coalesce(cultivar, '')), 'A') ||
          setweight(to_tsvector('english', coalesce(common_name, '')), 'A')
        ) STORED;
    """

    execute """
      CREATE INDEX taxonomy_searchable_idx ON taxonomy_search USING gin(searchable);
    """
  end
end
