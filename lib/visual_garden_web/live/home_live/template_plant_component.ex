defmodule VisualGardenWeb.HomeLive.TemplatePlantComponent do
  alias VisualGarden.Gardens.Garden
  alias VisualGarden.Gardens
  use VisualGardenWeb, :live_component

  def render(assigns) do
    ~H"""
    <div>
      <%= if @gardens != [] do %>
      <% else %>
        <.link patch={~p"/home/new_garden"}>
          <.button>
            Create a garden
          </.button>
        </.link>
        <.modal :if={@action in [:new_garden]} id="garden-modal" show on_cancel={JS.patch(~p"/home")}>
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
    </div>
    """
  end

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:gardens, Gardens.list_gardens(assigns.current_user))}
  end

  def handle_info({VisualGardenWeb.GardenLive.FormComponent, {:saved, garden}}, socket) do
    {:noreply, socket |> assign(:gardens, Gardens.list_garden_users(socket.assigns.current_user))}
  end
end
