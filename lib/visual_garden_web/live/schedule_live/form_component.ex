defmodule VisualGardenWeb.ScheduleLive.FormComponent do
  use VisualGardenWeb, :live_component
  alias VisualGarden.Library

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage schedule records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="schedule-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.live_select field={@form[:region_id]} label="Region" phx-target={@myself} options={@regions}>
          <:option :let={opt}>
            <%= Phoenix.HTML.raw(opt) %>
          </:option>
        </.live_select>
        <.live_select
          field={@form[:species_id]}
          label="Species"
          phx-target={@myself}
          options={@species}
        >
          <:option :let={opt}>
            <%= Phoenix.HTML.raw(opt) %>
          </:option>
        </.live_select>
        <.input field={@form[:start_month]} type="number" label="Start month" />
        <.input field={@form[:start_day]} type="number" label="Start day" />
        <.input field={@form[:end_month]} type="number" label="End month" />
        <.input field={@form[:end_day]} type="number" label="End day" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Schedule</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{schedule: schedule} = assigns, socket) do
    changeset = Library.change_schedule(schedule)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       :regions,
       Library.list_regions()
       |> Enum.map(fn region -> %{label: html_escape(region.name), value: region.id} end)
     )
     |> assign(
       :species,
       Library.list_species()
       |> Enum.map(fn species ->
         %{
           label: html_escape(species.genus.name <> " " <> species.name <> cultivar(species)),
           value: species.id
         }
       end)
     )
     |> assign_form(changeset)}
  end

  defp cultivar(species) do
    case species.cultivar do
      nil -> ""
      cv -> " '#{cv}'"
    end
  end

  @impl true
  def handle_event("live_select_change", %{"text" => _text, "id" => live_select_id}, socket) do
    # genera = Library.list_genera()
    # IO.inspect(live_select_id)
    # send_update(LiveSelect.Component, id: live_select_id, options: genera)

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate", %{"schedule" => schedule_params}, socket) do
    changeset =
      socket.assigns.schedule
      |> Library.change_schedule(schedule_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"schedule" => schedule_params}, socket) do
    save_schedule(socket, socket.assigns.action, schedule_params)
  end

  defp save_schedule(socket, :edit, schedule_params) do
    case Library.update_schedule(socket.assigns.schedule, schedule_params) do
      {:ok, schedule} ->
        notify_parent({:saved, schedule})

        {:noreply,
         socket
         |> put_notification(Normal.new(:info, "Schedule updated successfully"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_schedule(socket, :new, schedule_params) do
    case Library.create_schedule(schedule_params) do
      {:ok, schedule} ->
        notify_parent({:saved, schedule})

        {:noreply,
         socket
         |> put_notification(Normal.new(:info, "Schedule created successfully"))
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
