defmodule VisualGardenWeb.GenusLive.FormComponent do
  use VisualGardenWeb, :live_component

  alias VisualGarden.Library

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage genus records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="genus-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Genus</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{genus: genus} = assigns, socket) do
    changeset = Library.change_genus(genus)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"genus" => genus_params}, socket) do
    changeset =
      socket.assigns.genus
      |> Library.change_genus(genus_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"genus" => genus_params}, socket) do
    save_genus(socket, socket.assigns.action, genus_params)
  end

  defp save_genus(socket, :edit, genus_params) do
    case Library.update_genus(socket.assigns.genus, genus_params) do
      {:ok, genus} ->
        notify_parent({:saved, genus})

        {:noreply,
         socket
         |> put_flash(:info, "Genus updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_genus(socket, :new, genus_params) do
    case Library.create_genus(genus_params) do
      {:ok, genus} ->
        notify_parent({:saved, genus})

        {:noreply,
         socket
         |> put_flash(:info, "Genus created successfully")
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
