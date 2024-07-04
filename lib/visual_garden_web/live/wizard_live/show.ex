defmodule VisualGardenWeb.WizardLive.Show do
  use VisualGardenWeb, :live_view

  alias VisualGarden.Planner
  alias VisualGarden.Gardens
  alias VisualGarden.Library
  alias VisualGarden.MyDateTime

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:current_step, :region_selection)}
  end

  @impl true
  def handle_params(_params, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))}
  end

  @impl true
  def handle_event("next", _, socket) do
    current_step = socket.assigns.current_step

    case current_step do
      :region_selection ->
        {:noreply, socket |> assign(:current_step, :bed_creation)}

      :bed_creation ->
        {:noreply, socket |> assign(:current_step, :cultivar_selection)}

      :cultivar_selection ->
        {:noreply, socket |> assign(:current_step, :scheduling)}

      :scheduling ->
        {:noreply, socket |> assign(:current_step, :complete)}

      :complete ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("prev", _, socket) do
    current_step = socket.assigns.current_step

    case current_step do
      :region_selection ->
        {:noreply, socket}

      :bed_creation ->
        {:noreply, socket |> assign(:current_step, :region_selection)}

      :cultivar_selection ->
        {:noreply, socket |> assign(:current_step, :bed_creation)}

      :scheduling ->
        {:noreply, socket |> assign(:current_step, :cultivar_selection)}

      :complete ->
        {:noreply, socket |> assign(:current_step, :scheduling)}
    end
  end

  defp page_title(:show), do: "Show Wizard"

  defp render_region_selection(assigns) do
    # Stub page with a button going forward
    ~H"""
    <div class="div">
      <h3><%= @current_step %></h3>
      <.button phx-click="next">
        Next
      </.button>
    </div>
    """
  end

  defp render_bed_creation(assigns) do
    ~H"""
    <div class="div">
      <h3><%= @current_step %></h3>
      <.button phx-click="prev">
        Prev
      </.button>

      <.button phx-click="next">
        Next
      </.button>
    </div>
    """
  end

  defp render_cultivar_selection(assigns) do
    ~H"""
    <div class="div">
      <h3><%= @current_step %></h3>
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
      <h3><%= @current_step %></h3>
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
      <h3><%= @current_step %></h3>
      <.button phx-click="prev">
        Prev
      </.button>
    </div>
    """
  end

  def render(assigns) do
    current_step = assigns.current_step

    case current_step do
      :region_selection ->
        render_region_selection(assigns)

      :bed_creation ->
        render_bed_creation(assigns)

      :cultivar_selection ->
        render_cultivar_selection(assigns)

      :scheduling ->
        render_scheduling(assigns)

      :complete ->
        render_complete(assigns)
    end
  end
end
