defmodule VisualGardenWeb.HarvestLive.FormComponent do
  use VisualGardenWeb, :live_component

  alias VisualGarden.Gardens

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage harvest records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="harvest-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:quantity]} type="number" label="Quantity" step="any" />
        <.input field={@form[:units]} type="select" label="Units" options={VisualGarden.Gardens.Harvest.unit_options()}/>
        <:actions>
          <.button phx-disable-with="Saving...">Save Harvest</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{harvest: harvest} = assigns, socket) do
    changeset = Gardens.change_harvest(harvest)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"harvest" => harvest_params}, socket) do
    changeset =
      socket.assigns.harvest
      |> Gardens.change_harvest(harvest_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"harvest" => harvest_params}, socket) do
    save_harvest(socket, socket.assigns.action, harvest_params)
  end

  defp save_harvest(socket, :edit, harvest_params) do
    case Gardens.update_harvest(socket.assigns.harvest, harvest_params) do
      {:ok, harvest} ->
        notify_parent({:saved, harvest})

        {:noreply,
         socket
         |> put_flash(:info, "Harvest updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_harvest(socket, :new, harvest_params) do
    case Gardens.create_harvest(harvest_params) do
      {:ok, harvest} ->
        notify_parent({:saved, harvest})

        {:noreply,
         socket
         |> put_flash(:info, "Harvest created successfully")
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
