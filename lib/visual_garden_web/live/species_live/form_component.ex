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
        <.input field={@form[:genus]} type="text" label="Genus" />
        <.input field={@form[:name]} type="text" label="Species" />
        <.input field={@form[:variant]} type="text" label="Variant" />
        <.input field={@form[:cultivar]} type="text" label="Cultivar" />
        <.input field={@form[:common_name]} type="text" label="Common Name" />
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

  defp value_mapper(struct) do
    %{label: html_escape(struct.name) |> safe_to_string(), value: struct.id}
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
