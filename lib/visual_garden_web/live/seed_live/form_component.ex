defmodule VisualGardenWeb.SeedLive.FormComponent do
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
        <:actions>
          <.button phx-disable-with="Saving...">Save Seed</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{seed: seed} = assigns, socket) do
    changeset = Gardens.change_seed(seed)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"seed" => seed_params}, socket) do
    changeset =
      socket.assigns.seed
      |> Gardens.change_seed(seed_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"seed" => seed_params}, socket) do
    save_seed(socket, socket.assigns.action, seed_params)
  end

  defp save_seed(socket, :edit, seed_params) do
    case Gardens.update_seed(socket.assigns.seed, seed_params) do
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
    case Gardens.create_seed(seed_params) do
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
