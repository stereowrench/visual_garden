defmodule VisualGardenWeb.LibrarySeedLive.FormComponent do
  alias VisualGarden.Planner
  alias VisualGarden.Authorization
  alias VisualGardenWeb.KeywordHighlighter
  use VisualGardenWeb, :live_component

  alias VisualGarden.Library

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage library_seed records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="library_seed-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input
          field={@form[:type]}
          type="select"
          label="Type"
          prompt="Choose a value"
          options={Ecto.Enum.values(VisualGarden.Library.LibrarySeed, :type)}
        />
        <.input field={@form[:days_to_maturation]} type="number" label="Days to maturation" />
        <.input field={@form[:manufacturer]} type="text" label="Manufacturer" />
        <.live_select
          field={@form[:species_id]}
          label="Species"
          phx-target={@myself}
          options={@species}
          value_mapper={&to_string(&1)}
        >
          <:option :let={opt}>
            <.highlight matches={opt.matches} string={opt.label} />
          </:option>
        </.live_select>
        <:actions>
          <.button phx-disable-with="Saving...">Save Library seed</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def highlight(assigns) do
    KeywordHighlighter.highlight(assigns.string, assigns.matches)
  end

  @impl true
  def update(%{library_seed: library_seed} = assigns, socket) do
    changeset = Library.change_library_seed(library_seed)

    species = Planner.get_available_species(assigns.garden.region_id)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:species, species)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"library_seed" => library_seed_params}, socket) do
    changeset =
      socket.assigns.library_seed
      |> Library.change_library_seed(library_seed_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"library_seed" => library_seed_params}, socket) do
    Authorization.authorize_library(socket.assigns.current_user)
    save_library_seed(socket, socket.assigns.action, library_seed_params)
  end

  def handle_event("live_select_change", %{"text" => text, "id" => live_select_id}, socket) do
    matches =
      Seqfuzz.matches(socket.assigns.species, text, & &1.label, filter: true, sort: true)

    opts =
      matches
      |> Enum.map(fn {species, c} ->
        %{value: species.value, label: species.label, matches: c.matches}
      end)
      |> Enum.take(10)

    send_update(LiveSelect.Component, id: live_select_id, options: opts)
    {:noreply, socket}
  end

  defp save_library_seed(socket, :edit, library_seed_params) do
    case Library.update_library_seed(socket.assigns.library_seed, library_seed_params) do
      {:ok, library_seed} ->
        notify_parent({:saved, library_seed})

        {:noreply,
         socket
         |> put_notification(Normal.new(:info, "Library seed updated successfully"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_library_seed(socket, :new, library_seed_params) do
    case Library.create_library_seed(library_seed_params) do
      {:ok, library_seed} ->
        notify_parent({:saved, library_seed})

        {:noreply,
         socket
         |> put_notification(Normal.new(:info, "Library seed created successfully"))
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
