defmodule VisualGardenWeb.GardenLive.FormComponent do
  alias VisualGarden.Library
  use VisualGardenWeb, :live_component

  alias VisualGarden.Gardens
  alias VisualGardenWeb.KeywordHighlighter

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage garden records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="garden-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} label="Name" />
        <.live_select
          field={@form[:tz]}
          value_mapper={&to_string(&1)}
          label="Timezone"
          phx-target={@myself}
          options={@tz_opts}
        >
          <:option :let={opt}>
            <.highlight matches={opt.matches} string={opt.label} />
          </:option>
        </.live_select>
        <.live_select
          field={@form[:region_id]}
          label="Region"
          phx-target={@myself}
          options={@region_opts}
          value_mapper={&to_string(&1)}
        >
          <:option :let={opt}>
            <.highlight matches={opt.matches} string={opt.label} />
          </:option>
        </.live_select>
        <:actions>
          <.button phx-disable-with="Saving...">Save Garden</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{garden: garden} = assigns, socket) do
    changeset = Gardens.change_garden(garden)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:tz_opts, tz_opts())
     |> assign(:region_opts, region_opts())
     |> assign(:region_opts_stored, region_opts())
     |> assign_form(changeset)}
  end

  defp tz_opts do
    Tzdata.zone_list()
    |> Enum.map(fn a -> %{label: a, value: to_string(a), matches: []} end)
  end

  defp region_opts do
    Library.list_regions()
    |> Enum.map(fn a -> %{label: a.name, value: to_string(a.id), matches: []} end)
  end

  def highlight(assigns) do
    KeywordHighlighter.highlight(assigns.string, assigns.matches)
  end

  def handle_event("change", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "live_select_change",
        %{"text" => text, "id" => live_select_id = "garden_tz_live_select_component"},
        socket
      ) do
    matches = Seqfuzz.matches(tz_opts(), text, & &1.label, filter: true, sort: true)

    opts =
      Enum.map(matches, fn {map, c} ->
        %{label: map.label, value: map.value, matches: c.matches}
      end)
      |> Enum.take(10)

    send_update(LiveSelect.Component, id: live_select_id, options: opts)

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "live_select_change",
        %{"text" => text, "id" => live_select_id = "garden_region_id_live_select_component"},
        socket
      ) do
    matches =
      Seqfuzz.matches(socket.assigns.region_opts_stored, text, & &1.label,
        filter: true,
        sort: true
      )

    opts =
      Enum.map(matches, fn {map, c} ->
        %{label: map.label, value: map.value, matches: c.matches}
      end)
      |> Enum.take(10)

    send_update(LiveSelect.Component, id: live_select_id, options: opts)

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate", %{"garden" => garden_params}, socket) do
    changeset =
      socket.assigns.garden
      |> Gardens.change_garden(
        Map.merge(garden_params, %{"owner_id" => socket.assigns.current_user.id})
      )
      |> Map.put(:action, :validate)

    {:noreply, socket |> assign_form(changeset) |> assign(:changes, garden_params)}
  end

  def handle_event("save", %{"garden" => garden_params}, socket) do
    save_garden(socket, socket.assigns.action, garden_params)
  end

  defp save_garden(socket, :edit, garden_params) do
    case Gardens.update_garden(socket.assigns.garden, garden_params) do
      {:ok, garden} ->
        notify_parent({:saved, garden})

        {:noreply,
         socket
         |> put_notification(Normal.new(:info, "Garden updated successfully"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_garden(socket, :new, garden_params) do
    case Gardens.create_garden(
           Map.merge(garden_params, %{"owner_id" => socket.assigns.current_user.id})
         ) do
      {:ok, garden} ->
        notify_parent({:saved, garden})

        {:noreply,
         socket
         |> put_notification(Normal.new(:info, "Garden created successfully"))
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
