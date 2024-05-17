defmodule VisualGardenWeb.PlantLive.FormComponent do
  alias VisualGarden.Planner
  alias VisualGarden.Gardens.Plant
  use VisualGardenWeb, :live_component

  alias VisualGarden.Gardens

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage plant records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="plant-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:qty]} type="number" label="Quantity" />
        <%= if @action != :edit do %>
          <.input
            field={@form[:seed_id]}
            type="select"
            label="Seed"
            prompt="Choose a seed"
            options={["New Seed": -1] ++ Enum.map(@seeds, &{&1.name, &1.id})}
          />
          <%= if get_field(@form, :seed_id) == "-1" do %>
            <.inputs_for :let={seed} field={@form[:seed]}>
              <.input label="Seed Name" type="text" field={seed[:name]} />
              <.input label="Seed Description" type="textarea" field={seed[:description]} />
            </.inputs_for>
          <% end %>

          <.input
            field={@form[:product_id]}
            type="select"
            label="Placed In"
            prompt="Choose a product to place it in"
            options={["New Product": -1] ++ Enum.map(@beds, &{&1.name, &1.id})}
          />
          <%= if get_field(@form, :product_id) == "-1" do %>
            <.inputs_for :let={product} field={@form[:product]}>
              <.input label="Bed Name" type="text" field={product[:name]} />
              <.input field={product[:type]} type="hidden" value="bed" />
              <.input field={product[:length]} label="Length" type="number" />
              <.input field={product[:width]} label="Width" type="number" />
            </.inputs_for>
          <% end %>
          <%= if @bed do %>
            <div class="square-grid" style={["--length: #{@bed.length};", "--width: #{@bed.width}"]}>
              <%= for {{_label, val}, idx} <- Enum.with_index(squares_options(@bed)) do %>
                <label class="square-label">
                  <input
                    class="square-check"
                    phx-update="ignore"
                    type="radio"
                    name="Square"
                    id={"square_picker_#{idx}"}
                    value={val}
                  />
                  <span></span>
                </label>
              <% end %>
            </div>
          <% end %>
        <% end %>
        <:actions>
          <.button phx-disable-with="Saving...">Save Plant</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  defp get_field(form, id) do
    form.params[to_string(id)]
  end

  @impl true
  def update(assigns, socket) do
    plant =
      case assigns[:plant] do
        nil -> %Plant{}
        p -> p
      end

    changeset = Gardens.change_plant(plant, %{garden_id: assigns.garden.id})

    socket =
      if Map.has_key?(assigns, :bed) do
        socket
      else
        assign(socket, :bed, nil)
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:plant, plant)
     |> assign_form(changeset)}
  end

  defp apply_stubs(params, garden) do
    params =
      if params["product_id"] == "-1" do
        params =
          if params["product"] do
            params
          else
            put_in(params["product"], %{})
          end

        put_in(params["product"]["garden_id"], garden.id)
      else
        params
      end

    if params["seed_id"] == "-1" do
      params =
        if params["seed"] do
          params
        else
          put_in(params["seed"], %{})
        end

      put_in(params["seed"]["garden_id"], garden.id)
    else
      params
    end
  end

  defp add_square(plant_params, bed, square) do
    loc =
      square
      |> Planner.parse_square(bed)

    case loc do
      {x, y} ->
        plant_params
        |> put_in(["row"], x)
        |> put_in(["column"], y)

      _ ->
        plant_params
    end
  end

  @impl true
  def handle_event("validate", %{"plant" => plant_params} = params, socket) do
    cleaned =
      plant_params
      |> apply_stubs(socket.assigns.garden)
      |> add_square(socket.assigns.bed, params["Square"])

    changeset =
      socket.assigns.plant
      |> Gardens.change_plant(cleaned)
      |> Map.put(:action, :validate)

    bed =
      case get_field(changeset, :product_id) do
        nil ->
          nil

        "" ->
          nil

        pid ->
          if plant_params["product_id"] in ["-1"] do
            length = plant_params["product"]["length"]
            width = plant_params["product"]["width"]

            if length && width do
              with {len, ""} <- Integer.parse(length),
                   {wid, ""} <- Integer.parse(width) do
                %{length: len, width: wid}
              else
                _ -> nil
              end
            end
          else
            Gardens.get_product!(pid)
          end
      end

    socket = assign(socket, :bed, bed)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"plant" => plant_params} = params, socket) do
    save_plant(socket, socket.assigns.action, plant_params, params["Square"])
  end

  defp save_plant(socket, :edit, plant_params, square) do
    plant_params =
      plant_params
      |> maybe_add_parents(socket.assigns.garden)
      |> add_square(socket.assigns.bed, square)

    case Gardens.update_plant(socket.assigns.plant, plant_params) do
      {:ok, plant} ->
        notify_parent({:saved, plant})

        {:noreply,
         socket
         |> put_notification(Normal.new(:info, "Plant updated successfully"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_plant(socket, action, plant_params, square) when action in [:plant, :new] do
    plant_params =
      plant_params
      |> maybe_add_parents(socket.assigns.garden)
      |> add_square(socket.assigns.bed, square)

    case Gardens.create_plant(plant_params) do
      {:ok, plant} ->
        {:ok, _} =
          Gardens.create_event_log("plant", %{
            "event_time" => DateTime.utc_now(),
            "plant_id" => plant.id,
            "product_id" => plant.product_id
          })

        notify_parent({:saved, plant})

        {:noreply,
         socket
         |> put_notification(Normal.new(:info, "Plant created successfully"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp maybe_add_parents(params, garden) do
    params =
      if params["seed_id"] == "-1" do
        put_in(params["seed"]["garden_id"], garden.id)
      else
        params
      end

    if params["product_id"] == "-1" do
      put_in(params["product"]["garden_id"], garden.id)
    else
      params
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp squares_options(bed) do
    for i <- 0..(bed.length - 1) do
      for j <- 0..(bed.width - 1) do
        if bed.width > bed.length do
          {"#{i}, #{j}", i * bed.width + j}
        else
          {"#{i}, #{j}", i * bed.length + j}
        end
      end
    end
    |> List.flatten()
  end
end
