defmodule VisualGardenWeb.GardenLive.FormComponent do
  use VisualGardenWeb, :live_component

  alias VisualGarden.Gardens

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
        <.input field={@form[:name]} label="Name"/>
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
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"garden" => garden_params}, socket) do
    changeset =
      socket.assigns.garden
      |> Gardens.change_garden(garden_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
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
         |> put_flash(:info, "Garden updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_garden(socket, :new, garden_params) do
    case Gardens.create_garden(garden_params) do
      {:ok, garden} ->
        notify_parent({:saved, garden})

        {:noreply,
         socket
         |> put_flash(:info, "Garden created successfully")
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
