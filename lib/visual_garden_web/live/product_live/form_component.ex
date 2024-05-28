defmodule VisualGardenWeb.ProductLive.FormComponent do
  alias VisualGarden.Authorization
  use VisualGardenWeb, :live_component

  alias VisualGarden.Gardens

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage products records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="products-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <%= if @action in [:new_bed, :edit_bed] do %>
          <.input type="hidden" field={@form[:type]} value="bed" options={[:bed]} />
          <.input type="number" field={@form[:length]} label="Length (ft.)" />
          <.input type="number" field={@form[:width]} label="Width (ft.)" />
        <% else %>
          <.input
            field={@form[:type]}
            type="select"
            label="Type"
            prompt="Choose a value"
            options={Ecto.Enum.values(VisualGarden.Gardens.Product, :type) -- [:bed]}
          />
        <% end %>
        <:actions>
          <.button phx-disable-with="Saving...">Save Product</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{product: product} = assigns, socket) do
    Authorization.authorize_garden_modify(assigns.garden.id, assigns.current_user)
    changeset = Gardens.change_product(product)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"product" => product_params}, socket) do
    changeset =
      socket.assigns.product
      |> Gardens.change_product(product_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"product" => product_params}, socket) do
    Authorization.authorize_garden_modify(socket.assigns.garden.id, socket.assigns.current_user)
    save_product(socket, socket.assigns.action, product_params)
  end

  defp save_product(socket, action, product_params) when action in [:edit, :edit_bed] do
    case Gardens.update_product(socket.assigns.product, product_params) do
      {:ok, product} ->
        notify_parent({:saved, product})

        {:noreply,
         socket
         |> put_notification(
           Normal.new(
             :info,
             "Products updated successfully",
             Flashy.Normal.Options.new(dismiss_time: :timer.seconds(10))
           )
         )
         #  |> put_notification(Normal.new(:info, "Products updated successfully"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_product(socket, action, product_params) when action in [:new, :new_bed] do
    case Gardens.create_product(product_params, socket.assigns.garden) do
      {:ok, product} ->
        notify_parent({:saved, product})

        {:noreply,
         socket
         |> put_notification(Normal.new(:info, "Products created successfully"))
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
