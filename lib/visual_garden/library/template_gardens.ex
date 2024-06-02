defmodule VisualGarden.Library.TemplateGardens do
  alias VisualGarden.Repo
  alias VisualGarden.Gardens
  alias VisualGarden.MyDateTime
  alias VisualGarden.Planner
  alias VisualGarden.Library

  def single_tomato_plant_from_nursery(garden, execute \\ false) do
    species = Library.get_species_by_common_name("Tomatoes")

    if species do
      seed = %{
        name: "My Tomato Plant",
        type: "transplant",
        description: "Tomato seed generated from template",
        garden_id: garden.id,
        species_id: species.id,
        days_to_maturation: 65
      }

      bed = %{
        length: 1,
        width: 1,
        type: "bed",
        name: "My Tomato plant"
      }

      sched =
        Planner.get_plantables_from_garden(
          bed,
          MyDateTime.utc_today(),
          nil,
          MyDateTime.utc_today(),
          [species],
          nil,
          [seed],
          garden,
          nil
        )
        |> Enum.sort_by(& &1.sow_start, Date)
        |> case do
          [a|_] -> a
          [] -> nil
        end

      if execute do
        Repo.transaction(fn ->
          {:ok, seed} = Gardens.create_seed(seed)
          {:ok, bed} = Gardens.create_product(bed, garden)

          planner_entry = %{
            start_plant_date: sched.sow_start,
            end_plant_date: sched.sow_end,
            days_to_maturity: seed.days_to_maturation,
            days_to_refuse: seed.days_to_maturation + 30,
            common_name: "Tomatoes",
            row: 0,
            column: 0,
            bed_id: bed.id,
            seed_id: seed.id
          }

          {:ok, _pe} =
            Planner.create_planner_entry(
              planner_entry,
              garden
            )
        end)
      else
        %{"start" => sched.sow_start}
      end
    else
      nil
    end
  end
end
