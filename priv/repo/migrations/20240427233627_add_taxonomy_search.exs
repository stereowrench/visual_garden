defmodule VisualGarden.Repo.Migrations.AddTaxonomySearch do
  use Ecto.Migration

  def up do
    execute """
    CREATE TABLE IF NOT EXISTS taxonomy_search (
    genus TEXT,
    species TEXT,
    cultivar TEXT,
    species_id integer,
    common_name TEXT
    );
    """

    execute """
    CREATE OR REPLACE FUNCTION update_genus()
    RETURNS TRIGGER AS $$
    BEGIN
    UPDATE taxonomy_search SET genus = NEW.name WHERE genus = OLD.name;
    RETURN NEW;
    END;
    $$ language 'plpgsql';
    """

    execute """
    CREATE OR REPLACE TRIGGER update_genus_trigger
    BEFORE UPDATE ON genera
    FOR EACH ROW
    EXECUTE PROCEDURE update_genus();
    """

    execute """
    CREATE OR REPLACE FUNCTION new_species()
    RETURNS TRIGGER AS $$
    BEGIN
    WITH genus AS (SELECT genera.name FROM genera WHERE genera.id = NEW.genus_id LIMIT 1)
    INSERT INTO taxonomy_search (genus, species, cultivar, species_id, common_name) VALUES ((select genus.name from genus), NEW.name, NEW.cultivar, NEW.id, NEW.common_name);
    RETURN NEW;
    END;
    $$ language 'plpgsql';
    """

    execute """
    CREATE OR REPLACE TRIGGER new_species_trigger
        BEFORE INSERT ON species
        FOR EACH ROW
        EXECUTE PROCEDURE new_species();
    """

    execute """
    CREATE OR REPLACE FUNCTION edit_species()
    RETURNS TRIGGER AS $$
    BEGIN
    UPDATE taxonomy_search SET species = NEW.name, cultivar = NEW.cultivar, common_name = NEW.common_name WHERE taxonomy_search.species_id = NEW.id;
    RETURN NEW;
    END;
    $$ language 'plpgsql';
    """

    execute """
    CREATE OR REPLACE TRIGGER edit_species_trigger
    BEFORE UPDATE ON species
    FOR EACH ROW
    EXECUTE PROCEDURE edit_species();
    """
  end
end
