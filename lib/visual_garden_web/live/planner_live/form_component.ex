defmodule VisualGardenWeb.PlannerLive.FormComponent do
  alias VisualGarden.Planner
  alias VisualGarden.Gardens.PlannerEntry
  alias VisualGarden.Gardens
  use VisualGardenWeb, :live_component

  alias VisualGarden.Library

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Planner Entry
      </.header>

      <.simple_form
        for={@form}
        id="planner-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          name="species"
          type="select"
          label="Select Species"
          options={@species}
          value={@species_selected}
        />
        <%= unless @species_selected == "" do %>
          <.input
            name="type"
            type="select"
            label="Select type"
            options={@seed_type_options}
            value={@type_selected}
          />
        <% end %>
        <%= unless @type_selected == "" do %>
          <.input
            name="plantable"
            type="select"
            label="Select plantable"
            options={@plantable_options}
            value={@plantable_selected}
          />
        <% end %>
        <%= unless @species_selected == "" or @type_selected == "" or @plantable_selected == "" do %>
          <.input
            field={@form[:start_plant_date]}
            type="date"
            label="Earliest Plant"
            min={@planner_map[:sow_start]}
            max={@form[:end_plant_date].value || @planner_map[:sow_end]}
          />
          <.input
            field={@form[:end_plant_date]}
            type="date"
            label="Latest Plant"
            min={@form[:start_plant_date].value || @planner_map[:sow_start]}
            max={@planner_map[:sow_end]}
          />
          <.input field={@form[:days_to_maturity]} type="hidden" value={@planner_map[:days]} />
          <.input field={@form[:seed_id]} type="hidden" value={@seed_id} />
          <.input field={@form[:bed_id]} type="hidden" value={@bed.id} />
          <.input field={@form[:row]} type="hidden" value={@row} />
          <.input field={@form[:column]} type="hidden" value={@column} />
          <.input field={@form[:common_name]} type="hidden" value={@species_selected} />
          <%= if @form[:end_plant_date].value not in ["", nil] do %>
            <.input
              type="date"
              name="refuse_date"
              label="Refuse date"
              min={get_start_refuse_date(@form[:end_plant_date].value, @planner_map[:days])}
              max={@end_refuse_date}
              value={@refuse_date}
            />
          <% end %>
        <% end %>
        <:actions>
          <.button phx-disable-with="Saving...">Save planner</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def get_start_refuse_date(epd, days) do
    epd
    |> Timex.shift(days: days)
  end

  @impl true
  def update(assigns, socket) do
    end_date = Planner.get_end_date(assigns.square, assigns.bed, assigns.start_date)

    plantables_parsed =
      assigns.plantables
      |> Enum.group_by(& &1.schedule.species.common_name)

    # garden
    # bed
    # extent_dates
    changeset = Planner.change_planner_entry(%PlannerEntry{})
    {square, ""} = Integer.parse(assigns.square)

    species =
      ["Choose a species": nil] ++
        (Map.keys(plantables_parsed)
         |> Enum.map(&{&1, &1}))

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:row, trunc((square - 1) / assigns.bed.length))
     |> assign(:column, rem(square - 1, assigns.bed.length))
     |> assign(:species_form, %{"species" => "species", "type" => "type"})
     |> assign(:species, species)
     |> assign(:species_selected, "")
     |> assign(:type_selected, "")
     |> assign(:plantable_selected, "")
     |> assign(:planner_map, %{})
     |> assign(:seed_id, nil)
     |> assign(:refuse_date, nil)
     |> assign(:end_refuse_date, end_date)
     |> assign(:plantables_parsed, plantables_parsed)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", params, socket) do
    sp_assigns =
      if species = params["species"] do
        species_sel = socket.assigns.plantables_parsed[species]

        seed_types =
          species_sel
          |> Enum.group_by(&"#{&1.type} -- #{&1.seed.name}")

        seed_type_options = Map.keys(seed_types)

        type = params["type"] || ""

        {plantable_options, plantable_map} =
          if type != "" do
            processed_types =
              seed_types[type]
              |> Enum.sort_by(& &1.sow_start)
              |> Enum.reverse()
              |> Enum.with_index()
              |> Enum.map(fn
                {e = %{sow_start: ss, sow_end: se, seed: seed, days: days}, idx} ->
                  ssf = Timex.format!(ss, "{relative}", :relative)
                  sef = Timex.format!(se, "{relative}", :relative)
                  str = "#{seed.name} (#{ssf} - #{sef}) #{days} days"
                  {idx, str, e}
              end)

            plantable_options =
              processed_types
              |> Enum.map(fn
                {idx, str, _} ->
                  {str, idx}
              end)

            plantable_map =
              processed_types
              |> Enum.map(fn
                {idx, _, e} -> {to_string(idx), e}
              end)
              |> Enum.into(%{})

            {plantable_options, plantable_map}
          else
            {"", %{}}
          end

        %{
          species_selected: species,
          plantable_map: plantable_map,
          plantable_options: ["Select a plantable": ""] ++ plantable_options,
          type_selected: type,
          seed_type_options: ["Select a type": ""] ++ seed_type_options,
          seed_types: seed_types
        }
      else
        %{}
      end

    socket = assign(socket, sp_assigns)

    plantable = params["plantable"] || ""

    {plantable_selected, plantable_data} =
      if plantable == "" do
        {"", %{}}
      else
        {plantable, socket.assigns.plantable_map[plantable]}
      end

    seed_id =
      if plantable_selected != "" do
        plantable_data.seed.id
      else
        nil
      end

    socket =
      socket
      |> assign(:plantable_selected, plantable_selected)
      |> assign(:seed_id, seed_id)
      |> assign(:planner_map, plantable_data)

    socket =
      if planner_params = params["planner_entry"] do
        planner_params =
          if params["refuse_date"] && planner_params["end_plant_date"] not in [nil, ""] do
            add_params(planner_params, params, socket)
          else
            planner_params
          end

        changeset =
          %PlannerEntry{}
          |> Library.change_planner_entry(planner_params)
          |> Map.put(:action, :validate)

        assign_form(socket, changeset)
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_event("save", %{"planner_entry" => planner_params} = params, socket) do
    save_planner(socket, socket.assigns.action, planner_params, params)
  end

  defp add_params(planner_params, params, socket) do
    with {:ok, plant_date} <- Date.from_iso8601(planner_params["end_plant_date"]),
         {:ok, refuse_date} <- Date.from_iso8601(params["refuse_date"]) do
      Map.merge(
        %{"days_to_refuse" => Timex.diff(refuse_date, plant_date, :days)},
        planner_params
      )
    else
      _ -> planner_params
    end
  end

  defp save_planner(socket, :edit, planner_params, params) do
  end

  defp save_planner(socket, :new, planner_params, params) do
    case planner_params |> add_params(params, socket) |> Planner.create_planner_entry() do
      {:ok, planner_entry} ->
        notify_parent({:saved, planner_entry})

        {:noreply,
         socket
         |> put_notification(Normal.new(:info, "Planner entry created successfully"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        dbg(changeset)
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
