defmodule VisualGardenWeb.ProductLive.BedBulkComponent do
  use VisualGardenWeb, :live_component

  alias VisualGarden.Gardens

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <%!-- <:subtitle></:subtitle> --%>
      </.header>
      <form phx-target={@myself} phx-change="validate" phx-submit="save">
        <div class="square-grid" style={["--length: #{@bed.length};", "--width: #{@bed.width}"]}>
          <%= for {{_label, val}, idx} <- Enum.with_index(Gardens.squares_options(@bed)) do %>
            <label class="square-label" style={["--content: '#{content_for_cell(@plants, val)}'"]}>
              <input
                class="square-check"
                phx-update="ignore"
                type="checkbox"
                disabled={!@allow_empty && !has_plant(@plants, idx)}
                name="Square[]"
                id={"square_picker_#{idx}"}
                value={val}
              />
              <span></span>
            </label>
          <% end %>
        </div>
        <.button phx-disable-with="Saving...">Save Seed</.button>
      </form>
    </div>
    """
  end

  defp content_for_cell(plants, idx) do
    Gardens.content_for_cell(plants, idx)
  end

  defp has_plant(plants, idx) do
    (plants[idx] || []) != []
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("save", %{"Square" => squares}, socket) do
    case socket.assigns.action do
      :bulk_weed ->
        Gardens.create_event_logs("weed", squares, socket.assigns.bed)
        # TODO close modal
        {:noreply, socket}
    end
  end

  @impl true
  def update(assigns, socket) do
    plants =
      Gardens.list_plants(assigns.bed.garden_id, assigns.bed.id)
      |> Enum.group_by(fn plant ->
        Gardens.row_col_to_square(plant.row, plant.column, assigns.bed)
      end)

    {:ok,
     socket
     |> assign(:allow_empty, allow_empty(assigns.action))
     |> assign(:title, title(assigns.action))
     |> assign(:plants, plants)
     |> assign(assigns)}
  end

  defp allow_empty(:bulk_weed), do: true
  defp allow_empty(:bulk_trim), do: false
  defp allow_empty(:bulk_harvest), do: false

  defp title(:bulk_weed), do: "Bulk Weed"
  defp title(:bulk_trim), do: "Bulk Trim"
  defp title(:bulk_harvest), do: "Bulk Harvest"
end
