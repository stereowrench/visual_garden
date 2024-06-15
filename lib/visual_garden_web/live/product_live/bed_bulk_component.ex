defmodule VisualGardenWeb.ProductLive.BedBulkComponent do
  alias VisualGarden.Authorization.UnauthorizedError
  alias VisualGarden.Authorization
  use VisualGardenWeb, :live_component
  alias VisualGardenWeb.KeywordHighlighter

  alias VisualGarden.Gardens.EventLog
  alias VisualGarden.Gardens

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= title(assigns.action) %>
        <:subtitle>Select the squares you want to apply the action to.</:subtitle>
      </.header>
      <.simple_form
        for={@form}
        id="event_log-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
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

        <%= if @action == :transfer do %>
          <span>
            If the list is empty you need to
            <.link class="underline" navigate={~p"/gardens/#{@garden.id}/products/new"}>
              add fertilizers, compost, or growing media
            </.link>
            to your garden's inventory.
          </span>
          <.live_select
            field={@form[:transferred_from_id]}
            value_mapper={&to_string(&1)}
            label="Transferred from"
            phx-target={@myself}
            options={@product_opts}
          >
            <:option :let={opt}>
              <.highlight matches={opt.matches} string={opt.label} />
            </:option>
          </.live_select>

          <.input
            field={@form[:transferred_amount]}
            type="number"
            label="Transferred amount"
            step="any"
          />

          <.input
            field={@form[:transfer_units]}
            type="select"
            label="Units"
            prompt="Choose a value"
            options={Ecto.Enum.values(VisualGarden.Gardens.EventLog, :transfer_units)}
          />
        <% end %>
        <%= if @ready? do %>
          <.button phx-disable-with="Saving...">Save</.button>
        <% else %>
          <.button disabled>Save</.button>
        <% end %>
      </.simple_form>
    </div>
    """
  end

  defp content_for_cell(plants, idx) do
    Gardens.content_for_cell(plants, idx)
  end

  defp has_plant(plants, idx) do
    (plants[idx] || []) != []
  end

  defp merge_attrs(params, action, product) do
    Map.merge(
      %{
        "event_type" => event_type_for_action(action),
        "product_id" => product.id,
        "transferred_to_id" => product.id
      },
      params
    )
  end

  @impl true
  def handle_event("validate", %{"event_log" => event_log_params} = params, socket) do
    changeset =
      socket.assigns.event_log
      |> Gardens.change_event_log(
        merge_attrs(event_log_params, socket.assigns.action, socket.assigns.bed)
      )
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset) |> assign(:ready?, !!params["Square"])}
  end

  @impl true
  def handle_event("validate", params, socket) do
    {:noreply, socket |> assign(:ready?, !!params["Square"])}
  end

  def handle_event("save", %{"Square" => squares} = params, socket) do
    Authorization.authorize_garden_modify(
      socket.assigns.bed.garden_id,
      socket.assigns.current_user
    )

    case socket.assigns.action do
      :bulk_weed ->
        Gardens.create_event_logs("weed", squares, socket.assigns.bed)
        notify_parent(:bulk_saved)
        {:noreply, socket |> push_patch(to: socket.assigns.patch)}

      :bulk_harvest ->
        nil
        # TODO
        notify_parent(:bulk_saved)
        {:noreply, socket |> push_patch(to: socket.assigns.patch)}

      :bulk_trim ->
        Gardens.create_event_logs("trim", squares, socket.assigns.bed)
        notify_parent(:bulk_saved)
        {:noreply, socket |> push_patch(to: socket.assigns.patch)}

      :transfer ->
        p = Gardens.get_product!(params["event_log"]["transferred_from_id"])

        if p.garden_id != socket.assigns.garden.id do
          raise UnauthorizedError
        end

        pms = params["event_log"]
        pms = Map.put(pms, "transferred_to_id", socket.assigns.bed.id)
        Gardens.create_event_logs("transfer", squares, socket.assigns.bed, pms)
        notify_parent(:bulk_saved)
        {:noreply, socket |> push_patch(to: socket.assigns.patch)}
    end
  end

  def handle_event(
        "live_select_change",
        %{"text" => text, "id" => live_select_id = _},
        socket
      ) do
    matches =
      Seqfuzz.matches(socket.assigns.product_opts_all, text, & &1.label, filter: true, sort: true)

    opts =
      Enum.map(matches, fn {map, c} ->
        %{label: map.label, value: map.value, matches: c.matches}
      end)
      |> Enum.take(10)

    send_update(LiveSelect.Component, id: live_select_id, options: opts)

    {:noreply, socket}
  end

  defp event_type_for_action(:transfer), do: "transfer"
  defp event_type_for_action(_), do: nil

  @impl true
  def update(assigns, socket) do
    Authorization.authorize_garden_modify(assigns.bed.garden_id, assigns.current_user)

    plants =
      Gardens.list_plants(assigns.bed.garden_id, assigns.bed.id)
      |> Enum.reject(& &1.archived)
      |> Enum.group_by(fn plant ->
        Gardens.row_col_to_square(plant.row, plant.column, assigns.bed)
      end)

    el = %EventLog{}

    changeset =
      Gardens.change_event_log(el, %{
        "event_type" => event_type_for_action(assigns.action) || "water"
      })

    product_opts =
      Enum.map(assigns.products, fn p ->
        %{label: p.name, value: to_string(p.id), matches: []}
      end)

    {:ok,
     socket
     |> assign(:allow_empty, allow_empty(assigns.action))
     |> assign(:title, title(assigns.action))
     |> assign(:plants, plants)
     |> assign(:ready?, false)
     |> assign(
       :product_opts,
       product_opts
     )
     |> assign(
       :product_opts_all,
       product_opts
     )
     |> assign(:event_log, el)
     |> assign_form(changeset)
     |> assign(assigns)}
  end

  defp allow_empty(:bulk_weed), do: true
  defp allow_empty(:bulk_trim), do: false
  defp allow_empty(:bulk_harvest), do: false
  defp allow_empty(:transfer), do: true

  defp title(:bulk_weed), do: "Bulk Weed"
  defp title(:bulk_trim), do: "Bulk Trim"
  defp title(:bulk_harvest), do: "Bulk Harvest"
  defp title(:transfer), do: "Bulk Amend"

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  def highlight(assigns) do
    KeywordHighlighter.highlight(assigns.string, assigns.matches)
  end
end
