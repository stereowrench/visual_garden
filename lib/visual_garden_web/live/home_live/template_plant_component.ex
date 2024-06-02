defmodule VisualGardenWeb.HomeLive.TemplatePlantComponent do
  alias VisualGarden.Authorization
  alias VisualGarden.Library.TemplateGardens
  alias VisualGarden.Gardens.Garden
  alias VisualGarden.Gardens
  use VisualGardenWeb, :live_component

  def render(assigns) do
    ~H"""
    <div>
      <%= if @gardens != [] do %>
        <div class="prose">
          <%= for garden <- @gardens do %>
            <h3><%= garden.name %></h3>
            <%= for {name, template} <- @templates[garden.id] do %>
              <%= unless template == nil do %>
                <.link
                  class="underline"
                  phx-target={@myself}
                  phx-click={JS.push("template-#{name}", value: %{garden_id: garden.id})}
                  data-confirm="Are you sure?"
                >
                  Schedule single tomato in container (<%= Timex.format!(
                    template["start"],
                    "{relative}",
                    :relative
                  ) %>)
                </.link>
              <% end %>
            <% end %>
          <% end %>
        </div>
      <% else %>
        <%= if @current_user do %>
          <.link patch={~p"/home/new_garden"}>
            <.button>
              Create a garden
            </.button>
          </.link>
          <.modal
            :if={@action in [:new_garden]}
            id="garden-modal"
            show
            on_cancel={JS.patch(~p"/home")}
          >
            <.live_component
              module={VisualGardenWeb.GardenLive.FormComponent}
              id={:new}
              title={@title}
              current_user={@current_user}
              action={:new}
              garden={%Garden{}}
              patch={~p"/home"}
            />
          </.modal>
        <% end %>
      <% end %>
    </div>
    """
  end

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_templates()}
  end

  def assign_templates(socket) do
    templates =
      for garden <- socket.assigns.gardens do
        case TemplateGardens.single_tomato_plant_from_nursery(garden, false) do
          nil ->
            nil

          template ->
            {garden.id, [{"single_tomato", template}]}
        end
      end
      |> Enum.reject(&(&1 == nil))
      |> Enum.into(%{})

    assign(socket, templates: templates)
  end

  def handle_event("template-single_tomato", %{"garden_id" => garden_id}, socket) do
    Authorization.authorize_garden_modify(garden_id, socket.assigns.current_user)
    garden = Gardens.get_garden!(garden_id)
    TemplateGardens.single_tomato_plant_from_nursery(garden, true)
    notify_parent(:refresh)

    {:noreply, socket}
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
