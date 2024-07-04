defmodule VisualGardenWeb.WizardLive.Show do
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
     |> assign(:page_title, page_title(socket.assigns.live_action))}
  end

  @impl true
  def handle_event("prev", _, socket) do
    new_step = max(1, socket.assigns.step - 1)
    {:noreply, push_patch(socket, to: ~p"/wizard?#{[step: new_step]}")}
  end

  @impl true
  def handle_event("next", _, socket) do
    # Assuming 4 steps in total
    new_step = min(4, socket.assigns.step + 1)
    {:noreply, push_patch(socket, to: ~p"/wizard?#{[step: new_step]}")}
  end

  def handle_event("toggle_cell", %{"row" => row, "col" => col}, socket) do
    grid = socket.assigns.grid

    new_grid =
      List.update_at(grid, String.to_integer(row), fn cells ->
        List.update_at(cells, String.to_integer(col), &(!&1))
      end)

    IO.inspect(new_grid)
    {:noreply, assign(socket, grid: new_grid)}
  end

  defp page_title(:show), do: "Show Wizard"

  defp render_region_selection(assigns) do
    # Stub page with a button going forward
    ~H"""
    <div class="div">
      <h3>Setup</h3>
      <.button phx-click="next">
        Next
      </.button>
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
    <div class="div">
      <h3>Beds</h3>
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
    <div class="div">
      <h3>Cultivars</h3>
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
    <div class="div">
      <h3>Scheduling</h3>
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
    <div class="div">
      <h3>Review</h3>
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
        render_region_selection(assigns)

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
end
