defmodule VisualGardenWeb.SeedLive.FormComponent do
  alias VisualGarden.Library
  alias VisualGardenWeb.KeywordHighlighter
  use VisualGardenWeb, :live_component

  alias VisualGarden.Gardens

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage seed records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="seed-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:description]} type="text" label="Description" />
        <.input field={@form[:days_to_maturation]} type="number" label="Days to maturation" />
        <.live_select
          field={@form[:species_id]}
          label="Species"
          phx-target={@myself}
          options={@species}
        >
          <:option :let={opt}>
            <.highlight matches={@highlights[opt.label]} string={opt.label} />
          </:option>
        </.live_select>
        <:actions>
          <.button phx-disable-with="Saving...">Save Seed</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def highlight(assigns) do
    KeywordHighlighter.highlight(assigns.string, assigns.matches)
  end

  @impl true
  def update(%{seed: seed} = assigns, socket) do
    changeset = Gardens.change_seed(seed)

    species =
      Library.list_common_species()
      |> Enum.map(&%{label: &1.common_name, value: &1.id})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:species, species)
     |> assign(:highlights, %{})
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("live_select_change", %{"text" => text, "id" => live_select_id}, socket) do
    matches =
      Seqfuzz.matches(socket.assigns.species, text, & &1.label, filter: true, sort: true)

    opts = Enum.map(matches, fn {m, _} -> m end) |> Enum.take(10)

    highlights =
      matches
      |> Enum.map(fn {species, c} -> {species.label, c.matches} end)
      |> Enum.take(10)
      |> Enum.into(%{})

    send_update(LiveSelect.Component, id: live_select_id, options: opts)
    {:noreply, assign(socket, :highlights, highlights)}
  end

  @impl true
  def handle_event("validate", %{"seed" => seed_params}, socket) do
    prms = Map.merge(%{"garden_id" => socket.assigns.garden.id}, seed_params)

    changeset =
      socket.assigns.seed
      |> Gardens.change_seed(prms)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"seed" => seed_params}, socket) do
    save_seed(socket, socket.assigns.action, seed_params)
  end

  defp save_seed(socket, :edit, seed_params) do
    case Gardens.update_seed(
           socket.assigns.seed,
           Map.merge(%{"garden_id" => socket.assigns.garden.id}, seed_params)
         ) do
      {:ok, seed} ->
        notify_parent({:saved, seed})

        {:noreply,
         socket
         |> put_notification(Normal.new(:info, "Seed updated successfully"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_seed(socket, :new, seed_params) do
    case Gardens.create_seed(Map.merge(%{"garden_id" => socket.assigns.garden.id}, seed_params)) do
      {:ok, seed} ->
        notify_parent({:saved, seed})

        {:noreply,
         socket
         |> put_notification(Normal.new(:info, "Seed created successfully"))
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
