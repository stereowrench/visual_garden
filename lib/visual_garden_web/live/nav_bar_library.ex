defmodule VisualGardenWeb.NavBarLibrary do
  use VisualGardenWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mb-7">
      <div class="sm:hidden">
        <label for="tabs" class="sr-only">Select a tab</label>
        <!-- Use an "onChange" listener to redirect the user to the selected tab URL. -->
        <.form for={%{}} phx-change="select_tab" phx-target={@myself}>
          <select
            id="tabs"
            name="tabs"
            class="block w-full rounded-md border-gray-300 py-2 pl-3 pr-10 text-base focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 sm:text-sm"
          >
            <%= for {name, _path} <- routes() do %>
              <option selected={name == @current}><%= name %></option>
            <% end %>
          </select>
        </.form>
      </div>
      <div class="hidden sm:block">
        <div class="border-b border-eagle-200">
          <nav class="-mb-px flex space-x-8" aria-label="Tabs">
            <%= for {name, path} <- routes() do %>
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
        "border-eagle-600 text-eagle-800"
      else
        "border-transparent text-eagle-600 hover:border-eagle-300 hover:text-eagle-800"
      end

    common = "whitespace-nowrap border-b-2 py-4 px-1 text-sm font-medium"
    "#{custom} #{common}"
  end

  @impl true
  def handle_event("select_tab", params, socket) do
    {:noreply, push_redirect(socket, to: routes_map()[params["tabs"]])}
  end

  defp routes() do
    [
      {"Regions", ~p"/regions"},
      {"Plantables", ~p"/library_seeds"},
      {"Species", ~p"/species"},
      {"Schedules", ~p"/schedules"}
    ]
  end

  defp routes_map() do
    routes() |> Enum.into(%{})
  end
end
