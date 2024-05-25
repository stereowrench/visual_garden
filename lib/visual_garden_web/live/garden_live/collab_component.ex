defmodule VisualGardenWeb.GardenLive.CollabComponent do
  alias VisualGarden.Accounts
  alias VisualGarden.Library
  use VisualGardenWeb, :live_component

  alias VisualGarden.Gardens
  alias VisualGardenWeb.KeywordHighlighter

  defmodule EmailSchema do
    alias VisualGarden.Accounts
    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
      field :email, :string
    end

    def changeset(attrs \\ %{}) do
      %EmailSchema{}
      |> cast(attrs, [:email])
      |> validate_change(:email, fn :email, email ->
        if Accounts.get_user_by_email(email) do
          []
        else
          [email: "Not found!"]
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
    changeset = EmailSchema.changeset()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:users, Gardens.list_garden_users(assigns.garden))
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
        {:ok, _} = Gardens.create_garden_user(socket.assigns.garden, user)

        {:noreply,
         socket
         |> put_notification(Normal.new(:success, "Added a collaborator!"))
         |> push_patch(to: socket.assigns.patch)}

      %Ecto.Changeset{} = changeset ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
