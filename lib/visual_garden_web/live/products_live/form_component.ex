defmodule VisualGardenWeb.ProductsLive.FormComponent do
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
        <.input field={@form[:garden_id]}
          type="text"
          list="gardens-list"
          label="Garden"
        />
        <datalist :for={garden <- @gardens} id="gardens-list">
          <option value={garden.id}><%= garden.name %></option>
        </datalist>
        <.input field={@form[:name]} type="text" label="Name" />
        <.input
          field={@form[:type]}
          type="select"
          label="Type"
          prompt="Choose a value"
          options={Ecto.Enum.values(VisualGarden.Gardens.Product, :type)}
        />
        <:actions>
          <.button phx-disable-with="Saving...">Save Product</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{products: products} = assigns, socket) do
    changeset = Gardens.change_product(products)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"products" => products_params}, socket) do
    changeset =
      socket.assigns.products
      |> Gardens.change_product(products_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"products" => products_params}, socket) do
    save_products(socket, socket.assigns.action, products_params)
  end

  defp save_products(socket, :edit, products_params) do
    case Gardens.update_product(socket.assigns.products, products_params) do
      {:ok, products} ->
        notify_parent({:saved, products})

        {:noreply,
         socket
         |> put_flash(:info, "Products updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_products(socket, :new, products_params) do
    case Gardens.create_product(products_params) do
      {:ok, products} ->
        notify_parent({:saved, products})

        {:noreply,
         socket
         |> put_flash(:info, "Products created successfully")
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
