defmodule VisualGardenWeb.NavBar do
  use VisualGardenWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="sm:hidden">
        <label for="tabs" class="sr-only">Select a tab</label>
        <!-- Use an "onChange" listener to redirect the user to the selected tab URL. -->
        <.form for={%{}} phx-change="select_tab" phx-target={@myself}>
          <select
            id="tabs"
            name="tabs"
            class="block w-full rounded-md border-gray-300 py-2 pl-3 pr-10 text-base focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 sm:text-sm"
          >
            <%= for {name, _path} <- routes(@garden) do %>
              <option selected={name == @current}><%= name %></option>
            <% end %>
          </select>
        </.form>
      </div>
      <div class="hidden sm:block">
        <div class="border-b border-gray-200">
          <nav class="-mb-px flex space-x-8" aria-label="Tabs">
            <%= for {name, path} <- routes(@garden) do %>
              <.link navigate={path} class={link_style(name, @current)}><%= name %></.link>
            <% end %>
          </nav>
        </div>
      </div>
    </div>
    """
  end

  defp link_style(name, current) do
    custom =
      if name == current do
        "border-indigo-500 text-indigo-600"
      else
        "border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700"
      end

    common = "whitespace-nowrap border-b-2 py-4 px-1 text-sm font-medium"
    "#{custom} #{common}"
  end

  @impl true
  def handle_event("select_tab", params, socket) do
    {:noreply, push_redirect(socket, to: routes_map(socket.assigns.garden)[params["tabs"]])}
  end

  defp routes(garden) do
    [
      {"Home", ~p"/gardens/#{garden.id}"},
      {"Plants", ~p"/gardens/#{garden.id}/plants"},
      {"Seeds", ~p"/gardens/#{garden.id}/seeds"},
      {"Products", ~p"/gardens/#{garden.id}/products"},
      {"Beds", ~p"/gardens/#{garden.id}/beds"}
    ]
  end

  defp routes_map(garden) do
    routes(garden) |> Enum.into(%{})
  end
end
