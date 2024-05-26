defmodule VisualGardenWeb.RegionLive.FormComponent do
  alias VisualGarden.Authorization
  use VisualGardenWeb, :live_component

  alias VisualGarden.Library

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage region records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="region-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Region</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{region: region} = assigns, socket) do
    Authorization.authorize_library(assigns.current_user)
    changeset = Library.change_region(region)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"region" => region_params}, socket) do
    changeset =
      socket.assigns.region
      |> Library.change_region(region_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"region" => region_params}, socket) do
    Authorization.authorize_library(socket.assigns.current_user)
    save_region(socket, socket.assigns.action, region_params)
  end

  defp save_region(socket, :edit, region_params) do
    case Library.update_region(socket.assigns.region, region_params) do
      {:ok, region} ->
        notify_parent({:saved, region})

        {:noreply,
         socket
         |> put_notification(Normal.new(:info, "Region updated successfully"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_region(socket, :new, region_params) do
    case Library.create_region(region_params) do
      {:ok, region} ->
        notify_parent({:saved, region})

        {:noreply,
         socket
         |> put_notification(Normal.new(:info, "Region created successfully"))
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
