defmodule VisualGardenWeb.PlannerLive.FormComponent do
  alias VisualGarden.Authorization
  alias VisualGarden.Planner
  alias VisualGarden.Gardens.PlannerEntry
  use VisualGardenWeb, :live_component

  alias VisualGarden.Library

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Planner Entry
      </.header>
      <%= if @action in [:new, :new_bulk] do %>
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
            <%= if @planner_map[:type] == "nursery" do %>
              <.input
                field={@form[:nursery_start]}
                type="date"
                label="Earliest Nursery Plant"
                min={@planner_map[:nursery_start]}
                max={@form[:nursery_end].value || @planner_map[:nursery_end]}
              />
              <.input
                field={@form[:nursery_end]}
                type="date"
                label="Latest Nursery Plant"
                min={@form[:nursery_start].value || @planner_map[:nursery_start]}
                max={@planner_map[:nursery_end]}
              />
            <% else %>
              <%= if @nursery_start do %>
                Nursery dates: <%= @nursery_start %> to <%= @nursery_end %>
              <% end %>
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
            <% end %>
            <.input field={@form[:days_to_maturity]} type="hidden" value={@planner_map[:days]} />
            <.input field={@form[:min_lead]} type="hidden" value={@planner_map[:min_lead]} />
            <.input field={@form[:max_lead]} type="hidden" value={@planner_map[:max_lead]} />
            <.input field={@form[:seed_id]} type="hidden" value={@seed_id} />
            <.input field={@form[:bed_id]} type="hidden" value={@bed.id} />
            <.input field={@form[:row]} type="hidden" value={@row} />
            <.input field={@form[:column]} type="hidden" value={@column} />
            <.input field={@form[:common_name]} type="hidden" value={@species_selected} />
            <%= if @form[:end_plant_date].value not in ["", nil] or @form[:nursery_end].value not in ["", nil] do %>
              <.input
                type="date"
                name="refuse_date"
                label="Refuse date"
                min={
                  get_start_refuse_date(
                    @form[:end_plant_date].value,
                    @form[:nursery_end].value,
                    @planner_map[:days],
                    @planner_map
                  )
                }
                max={@end_refuse_date}
                value={@refuse_date}
              />
            <% end %>
          <% end %>
          <:actions>
            <.button phx-disable-with="Saving...">Save entry</.button>
          </:actions>
        </.simple_form>
      <% else %>
        <div class="prose">
          <h3>Nursery start</h3>
          <%= @planner_entry.nursery_start %>
          <h3>Nursery end</h3>
          <%= @planner_entry.nursery_end %>
          <h3>Start plant</h3>
          <%= @planner_entry.start_plant_date %>
          <h3>End plant</h3>
          <%= @planner_entry.end_plant_date %>
          <h3>Days to maturity</h3>
          <%= @planner_entry.days_to_maturity %>
          <h3>Days to refuse</h3>
          <%= @planner_entry.days_to_refuse %>

          <.simple_form
            for={@form}
            id="planner-form"
            phx-target={@myself}
            phx-change="validate"
            phx-submit="save"
          >
            <.input
              type="date"
              name="refuse_date"
              label="Refuse date"
              min={Timex.shift(@planner_entry.end_plant_date, days: @planner_entry.days_to_maturity)}
              max={@edit_end_refuse}
              value={Timex.shift(@planner_entry.end_plant_date, days: @planner_entry.days_to_refuse)}
            />
            <:actions>
              <.button phx-disable-with="Saving...">Save entry</.button>
            </:actions>
          </.simple_form>
        </div>
        <br />
        <.link
          phx-click={JS.push("delete", value: %{id: @planner_entry.id})}
          data-confirm="Are you sure?"
        >
          Delete
        </.link>
      <% end %>
    </div>
    """
  end

  def get_start_refuse_date(epd, nursery_end, days, _pm) do
    if epd == nil do
      Timex.shift(nursery_end, days: days)
    else
      Timex.shift(epd, days: days)
    end
  end

  @impl true
  def update(assigns, socket) do
    Authorization.authorize_garden_modify(assigns.garden.id, assigns.current_user)
    end_date = assigns.end_date

    plantables_parsed =
      assigns.plantables
      |> Enum.group_by(& &1.common_name)

    # garden
    # bed
    # extent_dates
    changeset = Planner.change_planner_entry(%PlannerEntry{}, assigns.garden)

    {row, column} =
      if assigns.square do
        Planner.parse_square(assigns.square, assigns.bed)
      else
        {nil, nil}
      end

    species =
      ["Choose a species": nil] ++
        (Map.keys(plantables_parsed)
         |> Enum.map(&{&1, &1}))

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:row, row)
     |> assign(:column, column)
     |> assign(:species_form, %{"species" => "species", "type" => "type"})
     |> assign(:species, species)
     |> assign(:species_selected, "")
     |> assign(:type_selected, "")
     |> assign(:plantable_selected, "")
     |> assign(:planner_map, %{})
     |> assign(:seed_id, nil)
     |> assign(:nursery_start, nil)
     |> assign(:nursery_end, nil)
     |> assign(:refuse_date, nil)
     |> assign(
       :edit_end_refuse,
       Planner.get_end_date(
         assigns.square,
         assigns.bed,
         assigns.planner_entry.end_plant_date,
         assigns.planner_entry.id
       )
     )
     |> assign(:can_edit?, Authorization.can_modify_garden?(assigns.garden, assigns.current_user))
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

        {ns, ne} = calculate_nursery_dates(socket, planner_params)

        changeset =
          %PlannerEntry{}
          |> Library.change_planner_entry(planner_params, socket.assigns.garden)
          |> Map.put(:action, :validate)

        socket
        |> assign_form(changeset)
        |> assign(:nursery_start, ns)
        |> assign(:nursery_end, ne)
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_event("save", %{"planner_entry" => planner_params} = params, socket) do
    {ns, ne} = calculate_nursery_dates(socket, planner_params)

    planner_params =
      if ns != nil && ne != nil do
        Map.merge(planner_params, %{
          "start_plant_date" => Date.to_string(ns),
          "end_plant_date" => Date.to_string(ne)
        })
      else
        planner_params
      end

    save_planner(socket, socket.assigns.action, planner_params, params)
  end

  def handle_event("save", %{"refuse_date" => rd}, socket) do
    Authorization.authorize_garden_modify(socket.assigns.garden.id, socket.assigns.current_user)
    {:ok, rd} = Date.from_iso8601(rd)
    rd_days = Timex.diff(rd, socket.assigns.planner_entry.end_plant_date, :days)

    val =
      Planner.update_planner_entry(
        socket.assigns.planner_entry,
        socket.assigns.garden,
        %{"days_to_refuse" => rd_days}
      )

    case val do
      {:ok, pe} ->
        notify_parent({:saved, pe})

        {:noreply,
         socket
         |> put_notification(Normal.new(:success, "Changed refuse date"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, changeset} ->
        {:noreply,
         socket
         |> put_notification(Normal.new(:warning, "Couldn't change date"))
         |> push_patch(to: socket.assigns.patch)}
    end
  end

  defp calculate_nursery_dates(socket, planner_params) do
    with pm when not is_nil(pm) <- socket.assigns.planner_map,
         "nursery" <- pm[:type],
         nss when nss != "" <- planner_params["nursery_start"],
         nes when nes != "" <- planner_params["nursery_end"],
         spd when not is_nil(spd) <- pm[:sow_start],
         epd when not is_nil(epd) <- pm[:sow_end] do
      ns = nss |> Date.from_iso8601!()
      ne = nes |> Date.from_iso8601!()

      ns = Planner.clamp_date(spd, epd, Timex.shift(ns, weeks: pm[:min_lead]))
      ne = Planner.clamp_date(spd, epd, Timex.shift(ne, weeks: pm[:max_lead]))

      {ns, ne}
    else
      _ -> {nil, nil}
    end
  end

  defp add_params(planner_params, params, _socket) do
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

  defp save_planner(_socket, :edit, _planner_params, _params) do
  end

  defp save_planner(socket, :new, planner_params, params) do
    Authorization.authorize_garden_modify(socket.assigns.garden.id, socket.assigns.current_user)

    case planner_params
         |> add_params(params, socket)
         |> Planner.create_planner_entry(socket.assigns.garden) do
      {:ok, planner_entry} ->
        notify_parent({:saved, planner_entry})

        {:noreply,
         socket
         |> put_notification(Normal.new(:info, "Planner entry created successfully"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_planner(socket, :new_bulk, planner_params, params) do
    Authorization.authorize_garden_modify(socket.assigns.garden.id, socket.assigns.current_user)

    res =
      VisualGarden.Repo.transaction(fn ->
        for square <- socket.assigns.squares do
          case planner_params
               |> add_params(params, socket)
               |> add_square(square, socket.assigns.bed)
               |> Planner.create_planner_entry(socket.assigns.garden) do
            {:ok, planner_entry} ->
              notify_parent({:saved, planner_entry})
              :ok

            {:error, %Ecto.Changeset{} = _changeset} ->
              VisualGarden.Repo.rollback(:error)
          end
        end
        |> Enum.all?(fn x -> x == :ok end)
        |> case do
          true -> :ok
          _ -> {:error, :error}
        end
      end)

    case res do
      {:ok, :ok} ->
        {:noreply,
         socket
         |> put_notification(Normal.new(:success, "Planner entries created successfully"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, _} ->
        {:noreply,
         socket
         |> put_notification(Normal.new(:danger, "Couldn't create planner entries"))}
    end
  end

  defp add_square(params, square, bed) do
    {row, column} = Planner.parse_square(square, bed)

    Map.merge(
      params,
      %{
        "row" => row,
        "column" => column
      }
    )
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
