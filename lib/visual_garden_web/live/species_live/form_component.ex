defmodule VisualGardenWeb.SpeciesLive.FormComponent do
  use VisualGardenWeb, :live_component
  alias VisualGarden.Library

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage species records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="species-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.live_select
          field={@form[:genus_id]}
          phx-target={@myself}
          label="Genus"
        />
        <:actions>
          <.button phx-disable-with="Saving...">Save Species</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{species: species} = assigns, socket) do
    changeset = Library.change_species(species)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("live_select_change", %{"text" => _text, "id" => live_select_id}, socket) do
    genera =
      Library.list_genera()
      |> Enum.map(&value_mapper/1)

    # |> Enum.map()

    send_update(LiveSelect.Component, id: live_select_id, options: genera)

    {:noreply, socket}
  end

  defp value_mapper(struct) do
    %{label: struct.name, value: struct.id}
  end

  @impl true
  def handle_event("validate", %{"species" => species_params}, socket) do
    changeset =
      socket.assigns.species
      |> Library.change_species(species_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"species" => species_params}, socket) do
    save_species(socket, socket.assigns.action, species_params)
  end

  defp save_species(socket, :edit, species_params) do
    case Library.update_species(socket.assigns.species, species_params) do
      {:ok, species} ->
        notify_parent({:saved, species})

        {:noreply,
         socket
         |> put_notification(Normal.new(:info, "Species updated successfully"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_species(socket, :new, species_params) do
    case Library.create_species(species_params) do
      {:ok, species} ->
        notify_parent({:saved, species})

        {:noreply,
         socket
         |> put_notification(Normal.new(:info, "Species created successfully"))
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
