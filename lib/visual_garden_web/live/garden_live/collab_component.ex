defmodule VisualGardenWeb.GardenLive.CollabComponent do
  alias VisualGarden.Authorization
  alias VisualGarden.Accounts
  use VisualGardenWeb, :live_component

  alias VisualGarden.Gardens

  defmodule EmailSchema do
    alias VisualGarden.Accounts
    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
      field :email, :string
    end

    def changeset(attrs \\ %{}, unique_error \\ false) do
      %EmailSchema{}
      |> cast(attrs, [:email])
      |> validate_change(:email, fn :email, email ->
        if Accounts.get_user_by_email(email) do
          []
        else
          [email: "Not found!"]
        end
      end)
      |> validate_change(:email, fn :email, _email ->
        if unique_error do
          [email: "Already added"]
        else
          []
        end
      end)
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>copy copy</:subtitle>
      </.header>

      <.table id="garden-users" rows={@users}>
        <:col :let={user} label="email"><%= user.user.email %></:col>
        <:action :let={user}>
          <.link
            phx-click={JS.push("delete", value: %{id: user.user_id})}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>

      <.simple_form
        for={@form}
        id="collab-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:email]}
          type="text"
          label="Add user by email"
          prompt="Choose a value"
          options={Ecto.Enum.values(VisualGarden.Gardens.Garden, :visibility)}
        />
        <:actions>
          <.button phx-disable-with="Saving...">Save Garden</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{garden: garden} = assigns, socket) do
    Authorization.authorize_garden_modify(garden.id, assigns.current_user)
    changeset = EmailSchema.changeset()

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  def handle_event("change", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("validate", %{"email_schema" => %{"email" => email}}, socket) do
    changeset = EmailSchema.changeset(%{email: email}) |> Map.put(:action, :validate)
    {:noreply, socket |> assign_form(changeset)}
  end

  def handle_event("save", %{"email_schema" => %{"email" => email}}, socket) do
    save_garden(socket, socket.assigns.action, email)
  end

  defp save_garden(socket, :collab, email) do
    case EmailSchema.changeset(%{email: email}) do
      %Ecto.Changeset{valid?: true} = es ->
        user = Accounts.get_user_by_email(Ecto.Changeset.get_field(es, :email))
        true = not is_nil(user)

        case Gardens.create_garden_user(socket.assigns.garden, user) do
          {:ok, _} ->
            notify_parent({:saved, user})

            {:noreply,
             socket
             |> send_notification(Normal.new(:success, "Added a collaborator!"))}

          {:error, _changeset} ->
            cs = EmailSchema.changeset(%{email: email}, true) |> Map.put(:action, :validate)

            {:noreply,
             socket
             |> send_notification(Normal.new(:warning, "User already added"))
             |> assign_form(cs)}
        end

      %Ecto.Changeset{} = changeset ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
