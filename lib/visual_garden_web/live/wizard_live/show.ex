defmodule VisualGardenWeb.WizardLive.Show do
  alias VisualGarden.Wizard
  use VisualGardenWeb, :live_view

  alias VisualGarden.Planner
  alias VisualGarden.Gardens
  alias VisualGarden.Library
  alias VisualGarden.MyDateTime

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:step, 1)
     |> assign(
       :grid,
       for(_ <- 1..3, do: for(_ <- 1..4, do: false))
     )}
  end

  @impl true
  def handle_params(params, _, socket) do
    {:noreply,
     socket
     |> assign(step: String.to_integer(params["step"] || "1"))
     |> assign(:garden, nil)
     |> assign(:wizard_garden, nil)
     |> assign(:params, [])
     |> assign(:new_garden, false)
     |> assign(:hide_garden, true)
     |> add_step_params(params)
     |> assign(:page_title, page_title(socket.assigns.live_action))}
  end

  def add_step_params(socket, params) do
    case socket.assigns.step do
      1 ->
        wg =
          if id = params["wizard_garden"] do
            Wizard.get_wizard_garden!(id, users_tuple(socket))
          else
            nil
          end

        socket
        |> assign(:wizard_gardens, Wizard.list_wizard_gardens(users_tuple(socket)))
        |> assign(:gardens, gardens_for_socket(socket))
        |> assign(:wizard_garden, wg)

      _ ->
        socket
    end
  end

  defp users_tuple(socket) do
    {socket.assigns.current_user, socket.assigns.temp_user}
  end

  def gardens_for_socket(socket) do
    if user = socket.assigns.current_user do
      Gardens.list_gardens(user)
    else
      []
    end
  end

  defp merge_state(socket) do
    new = socket.assigns.params
    push_patch(socket, to: ~p"/wizard?#{new}")
  end

  def add_param(socket, new_params) do
    assign(socket, :params, Keyword.merge(socket.assigns.params, new_params))
  end

  def clear_param(socket, key) do
    assign(socket, :params, Keyword.delete(socket.assigns.params, key))
  end

  def ensure_garden_remains_ok(socket) do
    # Check that the
  end

  @num_stages 5

  @impl true
  def handle_event("prev", _, socket) do
    new_step = max(1, socket.assigns.step - 1)
    {:noreply, socket |> add_param(step: new_step) |> merge_state()}
  end

  @impl true
  def handle_event("next", _, socket) do
    new_step = min(@num_stages, socket.assigns.step + 1)
    {:noreply, socket |> add_param(step: new_step) |> merge_state()}
  end

  @impl true
  def handle_event("toggle_cell", %{"row" => row, "col" => col}, socket) do
    grid = socket.assigns.grid

    new_grid =
      List.update_at(grid, String.to_integer(row), fn cells ->
        List.update_at(cells, String.to_integer(col), &(!&1))
      end)

    scaffolds = []
    {:noreply, assign(socket, grid: new_grid) |> add_param(scaffolds: scaffolds)}
  end

  def handle_event("select_garden", %{"garden" => garden_id}, socket) do
    user = socket.assigns.current_user
    Authorization.authorize_garden_modify(garden_id, user)

    garden = Gardens.get_garden!(garden_id)
    wizard_garden = Wizard.create_wizard_garden_from_garden!(garden, users_tuple(socket))

    {:noreply,
     socket
     |> add_param(wizard_garden: wizard_garden.id)
     |> assign(:garden, Gardens.get_garden!(garden_id))
     |> merge_state()}
  end

  def handle_event("new_garden", _, socket) do
    {:noreply, assign(socket, :new_garden, true)}
  end

  def handle_event("cancel", _, socket) do
    if socket.assigns.wizard_garden do
      Wizard.delete_wizard_garden!(socket.assigns.wizard_garden)
    end

    {:noreply,
     socket |> assign(:new_garden, false) |> clear_param(:wizard_garden) |> merge_state()}
  end

  def handle_event("clear_garden", _, socket) do
    {:noreply, assign(socket, :garden, nil)}
  end

  defp page_title(:show), do: "Show Wizard"

  defp render_setup(assigns) do
    ~H"""
    <.breadcrumbs socket={assigns} />
    <div class="prose">
      <h2>Setup</h2>
      <.button phx-click="next">
        Next
      </.button>
      <%= if @wizard_garden do %>
        <%= if @wizard_garden.garden_id do %>
          <.header>
            Planning for existing garden
            <:subtitle><%= @wizard_garden.garden.name %></:subtitle>
          </.header>
        <% else %>
          <.header>
            Planning for new garden
          </.header>
        <% end %>

        <.button phx-click="cancel">Cancel</.button>
      <% else %>
        <%= if @new_garden do %>
          <h3>Starting a new garden</h3>
          <.button phx-click="cancel">Cancel</.button>
        <% else %>
          <%= if @garden do %>
            <div class="prose">
              Wizard for garden: <%= @garden.name %>
            </div>
            <.button phx-click="clear_garden">Cancel</.button>
          <% else %>
            <h3>Start new</h3>
            <.button phx-click="new_garden">New Garden</.button>
            <div class="separator">or</div>
            <h3>Choose a Garden</h3>
            <%= for garden <- @gardens do %>
              <.button phx-click="select_garden" phx-value-garden={garden.id}>
                <%= garden.name %>
              </.button>
            <% end %>
          <% end %>
        <% end %>
      <% end %>
    </div>
    """
  end

  defp convert_grid(grid) do
    grid
    |> List.flatten()
    |> Enum.with_index()
  end

  defp render_bed_creation(assigns) do
    ~H"""
    <.breadcrumbs socket={assigns} />
    <div class="prose">
      <h2>Beds</h2>
      <.button phx-click="prev">
        Prev
      </.button>

      <.button phx-click="next">
        Next
      </.button>

      <div class="square-grid" style={["--length: #{4};", "--width: #{3}"]}>
        <%= for {val, idx} <- convert_grid(@grid) do %>
          <label class="square-label" style={["--content: '#{if val, do: "Scaffold", else: ""}"]}>
            <input
              class="square-check"
              type="checkbox"
              phx-click="toggle_cell"
              phx-value-col={rem(idx, 4)}
              phx-value-row={trunc(idx / 4)}
              id={"square_picker_#{idx}"}
              value={val}
            />
            <span></span>
          </label>
        <% end %>
      </div>
    </div>
    """
  end

  defp render_cultivar_selection(assigns) do
    ~H"""
    <.breadcrumbs socket={assigns} />
    <div class="prose">
      <h2>Cultivars</h2>
      <.button phx-click="prev">
        Prev
      </.button>

      <.button phx-click="next">
        Next
      </.button>
    </div>
    """
  end

  defp render_scheduling(assigns) do
    ~H"""
    <.breadcrumbs socket={assigns} />
    <div class="prose">
      <h2>Scheduling</h2>
      <.button phx-click="prev">
        Prev
      </.button>

      <.button phx-click="next">
        Next
      </.button>
    </div>
    """
  end

  defp render_complete(assigns) do
    ~H"""
    <.breadcrumbs socket={assigns} />
    <div class="prose">
      <h2>Review</h2>
      <.button phx-click="prev">
        Prev
      </.button>
    </div>
    """
  end

  def render(assigns) do
    current_step = assigns.step

    case current_step do
      1 ->
        render_setup(assigns)

      2 ->
        render_bed_creation(assigns)

      3 ->
        render_cultivar_selection(assigns)

      4 ->
        render_scheduling(assigns)

      5 ->
        render_complete(assigns)
    end
  end

  def name_for_step(1), do: "Setup"
  def name_for_step(2), do: "Beds"
  def name_for_step(3), do: "Cultivar"
  def name_for_step(4), do: "Scheduling"
  def name_for_step(5), do: "Complete"

  def patch_for_step(idx, socket) do
    pms = Keyword.put(socket.params, :step, idx)
    ~p"/wizard?#{pms}"
  end

  def breadcrumbs(assigns) do
    assigns =
      assign(assigns, %{
        num_stages: @num_stages
      })

    ~H"""
    <nav class="flex border-b border-gray-200 bg-white" aria-label="Breadcrumb">
      <ol role="list" class="mx-auto flex w-full max-w-screen-xl space-x-4 px-4 sm:px-6 lg:px-8">
        <%= for idx <- 1..@num_stages do %>
          <.breadcrumb_item
            name={name_for_step(idx)}
            patch={patch_for_step(idx, @socket)}
            gray={idx > @socket.step}
            active={@socket.step == idx}
          />
        <% end %>
      </ol>
    </nav>
    """
  end

  defp link_styles(active, gray) do
    if active do
      "ml-4 text-sm hover:text-gray-700 underline"
    else
      if gray do
        "ml-4 text-sm font-medium text-gray-500 hover:text-gray-700"
      else
        "ml-4 text-sm font-medium hover:text-gray-700"
      end
    end
  end

  defp breadcrumb_item(assigns) do
    ~H"""
    <li class="flex">
      <div class="flex items-center">
        <svg
          class="h-full w-6 flex-shrink-0 text-gray-200"
          viewBox="0 0 24 44"
          preserveAspectRatio="none"
          fill="currentColor"
          aria-hidden="true"
        >
          <path d="M.293 0l22 22-22 22h1.414l22-22-22-22H.293z" />
        </svg>
        <.link patch={@patch} class={link_styles(@active, @gray)}>
          <%= @name %>
        </.link>
      </div>
    </li>
    """
  end
end
