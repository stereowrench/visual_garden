defmodule VisualGardenWeb.ProductLive.FormComponent do
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
        <%!-- <.input field={@form[:garden_id]}
          type="text"
          list="gardens-list"
          label="Garden"
        />
        <datalist :for={garden <- @gardens} id="gardens-list">
          <option value={garden.id}><%= garden.name %></option>
        </datalist> --%>

        <.input field={@form[:name]} type="text" label="Name" />
        <%= if @action == :new_bed do %>
          <.input type="hidden" field={@form[:type]} value="bed" options={[:bed]} />
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
    save_product(socket, socket.assigns.action, product_params)
  end

  defp save_product(socket, :edit, product_params) do
    case Gardens.update_product(socket.assigns.product, product_params) do
      {:ok, product} ->
        notify_parent({:saved, product})

        {:noreply,
         socket
         |> put_flash(:info, "Products updated successfully")
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
