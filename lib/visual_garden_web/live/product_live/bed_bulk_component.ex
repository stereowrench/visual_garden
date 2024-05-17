defmodule VisualGardenWeb.ProductLive.BedBulkComponent do
  use VisualGardenWeb, :live_component

  alias VisualGarden.Gardens

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%= if @bed do %>
        <div class="square-grid" style={["--length: #{@bed.length};", "--width: #{@bed.width}"]}>
          <%= for {{_label, val}, idx} <- Enum.with_index(Gardens.squares_options(@bed)) do %>
            <label
              class="square-label"
              style={["--content: '#{content_for_cell(@plants, val)}'"]}
            >
              <input
                class="square-check"
                phx-update="ignore"
                type="checkbox"
                name="Square"
                id={"square_picker_#{idx}"}
                value={val}
              />
              <span></span>
            </label>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  defp content_for_cell(plants, idx) do
    if p = plants[idx] do
      if q = hd(p) do
        q.name
      else
        ""
      end
    else
      ""
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
     |> assign(:plants, plants)
     |> assign(assigns)}
  end
end
