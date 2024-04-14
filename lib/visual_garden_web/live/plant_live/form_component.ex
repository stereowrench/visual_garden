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
        <.input
          field={@form[:seed_id]}
          type="select"
          label="Seed"
          prompt="Choose a seed"
          options={["New Seed"] ++ Enum.map(@seeds, & &1.name)}
        />
        <%= if get_field(@form, :seed_id) == "New Seed" do %>
          <.inputs_for :let={seed} field={@form[:seed]}>
            <.input label="Seed Name" type="text" field={seed[:name]} />
            <.input label="Seed Description" type="textarea" field={seed[:description]} />
          </.inputs_for>
        <% end %>

        <.input
          field={@form[:product_id]}
          type="select"
          label="Placed In"
          prompt="Choose a seed"
          options={["New Product"] ++ Enum.map(@products, & &1.name)}
        />
        <%= if get_field(@form, :product_id) == "New Product" do %>
          <.inputs_for :let={product} field={@form[:product]}>
            <.input label="Product Name" type="text" field={product[:name]} />
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
    {params, rem} =
      if params["product_id"] == "New Product" and params["product"] == nil do
        params = put_in(params["product"], %{"garden_id" => garden.id})
        {params, %{product_id: "New Product"}}
      else
        {params, %{}}
      end

    if params["seed_id"] == "New Seed" and params["seed"] == nil do
      params = put_in(params["seed"], %{"garden_id" => garden.id})
      {params, Map.merge(rem, %{seed_id: "New Seed"})}
    else
      {params, rem}
    end
  end

  defp repair_changeset(changes, rem, products, seeds) do
    rem2 = Enum.map(rem, fn {a, b} -> {to_string(a), b} end) |> Enum.into(%{})

    new_chgs =
      rem
      |> Map.merge(changes.changes)
      |> Enum.map(
        fn
        ->
        end
      )
      |> Enum.into(%{})

    changes = Map.put(changes, :changes, new_chgs)

    changes = Map.put(changes, :params, Map.merge(rem2, changes.params))

    IO.inspect(changes)
  end

  @impl true
  def handle_event("validate", %{"plant" => plant_params}, socket) do
    {cleaned, rem} = apply_stubs(plant_params, socket.assigns.garden)

    changeset =
      socket.assigns.plant
      |> Gardens.change_plant(
        convert_ids(
          cleaned,
          socket.assigns.products,
          socket.assigns.seeds,
          false
        )
      )
      |> Map.put(:action, :validate)
      |> repair_changeset(rem, socket.assigns.products, socket.assigns.seeds)

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

  defp convert_ids(params, products, seeds, del \\ true) do
    params =
      if params["seed_id"] == "New Seed" do
        if del do
          Map.delete(params, "seed_id")
        else
          params
        end
      else
        new = Enum.find(seeds, &(&1.name == params["seed_id"]))

        if new do
          put_in(params["seed_id"], new.id)
        else
          params
        end
      end

    if params["product_id"] == "New Product" do
      if del do
        Map.delete(params, "product_id")
      else
        params
      end
    else
      new = Enum.find(products, &(&1.name == params["product_id"]))

      if new do
        put_in(params["product_id"], new.id)
      else
        params
      end
    end
  end

  defp drop_ids(params) do
    params =
      if params["seed_id"] == "New Seed" do
        Map.delete(params, "seed_id")
      else
        params
      end

    if params["product_id"] == "New Product" do
      Map.delete(params, "product_id")
    else
      params
    end
  end

  defp save_plant(socket, :plant, plant_params) do
    plant_params = maybe_add_parents(plant_params, socket.assigns.garden)
    plant_params = convert_ids(plant_params, socket.assigns.products, socket.assigns.seeds)
    plant_params = drop_ids(plant_params)

    case Gardens.create_plant(plant_params) do
      {:ok, plant} ->
        notify_parent({:saved, plant})

        {:noreply,
         socket
         |> put_notification(Normal.new(:info, "Plant created successfully"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
