defmodule VisualGardenWeb.NurseryEntryLive.FormComponent do
  use VisualGardenWeb, :live_component

  alias VisualGarden.Gardens

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage nursery_entry records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="nursery_entry-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:sow_date]} type="date" label="Sow date" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Nursery entry</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{nursery_entry: nursery_entry} = assigns, socket) do
    changeset = Gardens.change_nursery_entry(nursery_entry)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"nursery_entry" => nursery_entry_params}, socket) do
    nursery_entry_params =
      Map.merge(nursery_entry_params, %{"garden_id" => socket.assigns.garden.id})

    changeset =
      socket.assigns.nursery_entry
      |> Gardens.change_nursery_entry(nursery_entry_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"nursery_entry" => nursery_entry_params}, socket) do
    nursery_entry_params =
      Map.merge(nursery_entry_params, %{"garden_id" => socket.assigns.garden.id})

    save_nursery_entry(socket, socket.assigns.action, nursery_entry_params)
  end

  defp save_nursery_entry(socket, :edit, nursery_entry_params) do
    case Gardens.update_nursery_entry(socket.assigns.nursery_entry, nursery_entry_params) do
      {:ok, nursery_entry} ->
        notify_parent({:saved, nursery_entry})

        {:noreply,
         socket
         |> put_notification(Normal.new(:info, "Nursery entry updated successfully"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_nursery_entry(socket, :new, nursery_entry_params) do
    case Gardens.create_nursery_entry(nursery_entry_params) do
      {:ok, nursery_entry} ->
        notify_parent({:saved, nursery_entry})

        {:noreply,
         socket
         |> put_notification(Normal.new(:info, "Nursery entry created successfully"))
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
