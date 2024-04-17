defmodule VisualGardenWeb.PlantLive.FormComponent do
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
        <.input field={@form[:name]} type="text" label="Name"/>

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
          options={["New Product": -1] ++ Enum.map(@products, &{&1.name, &1.id})}
        />
        <%= if get_field(@form, :product_id) == "-1" do %>
          <.inputs_for :let={product} field={@form[:product]}>
            <.input label="Product Name" type="text" field={product[:name]} />
            <.input
              field={product[:type]}
              type="select"
              label="Type"
              prompt="Choose a value"
              options={Ecto.Enum.values(VisualGarden.Gardens.Product, :type) -- [:bed]}
            />
          </.inputs_for>
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
    plant = %Plant{}
    changeset = Gardens.change_plant(plant, %{garden_id: assigns.garden.id})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:plant, plant)
     |> assign_form(changeset)}
  end

  defp apply_stubs(params, garden) do
    params =
      if params["product_id"] == "New Product" and params["product"] == nil do
        put_in(params["product"], %{"garden_id" => garden.id})
      else
        params
      end

    if params["seed_id"] == "New Seed" and params["seed"] == nil do
      put_in(params["seed"], %{"garden_id" => garden.id})
    else
      params
    end
  end

  @impl true
  def handle_event("validate", %{"plant" => plant_params}, socket) do
    cleaned = apply_stubs(plant_params, socket.assigns.garden)

    changeset =
      socket.assigns.plant
      |> Gardens.change_plant(cleaned)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"plant" => plant_params}, socket) do
    save_plant(socket, socket.assigns.action, plant_params)
  end

  # defp save_plant(socket, :edit, plant_params) do
  #   case Gardens.update_plant(socket.assigns.plant, plant_params) do
  #     {:ok, plant} ->
  #       notify_parent({:saved, plant})

  #       {:noreply,
  #        socket
  #        |> put_notification(Normal.new(:info, "Plant updated successfully"))
  #        |> push_patch(to: socket.assigns.patch)}

  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       {:noreply, assign_form(socket, changeset)}
  #   end
  # end

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

  defp save_plant(socket, :plant, plant_params) do
    plant_params = maybe_add_parents(plant_params, socket.assigns.garden)

    case Gardens.create_plant(plant_params) do
      {:ok, plant} ->
        notify_parent({:saved, plant})
        {:noreply,
         socket
         |> put_notification(Normal.new(:info, "Plant created successfully"))
         |> push_patch(to: ~p"/gardens/#{socket.assigns.garden.id}/")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
