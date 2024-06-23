defmodule VisualGardenWeb.EventLogLive.FormComponent do
  alias VisualGardenWeb.KeywordHighlighter
  alias VisualGarden.Authorization.UnauthorizedError
  alias VisualGarden.Authorization
  alias VisualGarden.Gardens.EventLog
  use VisualGardenWeb, :live_component

  alias VisualGarden.Gardens

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
      </.header>

      <.simple_form
        for={@form}
        id="event_log-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          phx-hook="EventTime"
          field={@form[:event_time_hidden]}
          type="datetime-local"
          label="Event time"
          phx-update="ignore"
          value={VisualGarden.MyDateTime.utc_now()}
        />
        <.input id="event-time" field={@form[:event_time]} type="hidden" />

        <%= if @action == :new_humidity do %>
          <.input field={@form[:humidity]} type="number" label="Humidity" />
        <% end %>
        <%!-- <.input field={@form[:mowed]} type="checkbox" label="Mowed" />
        <.input field={@form[:mow_depth_in]} type="number" label="Mow depth in" step="any" /> --%>
        <%= if @action == :till do %>
          <.input field={@form[:till_depth_in]} type="number" label="Till depth in" step="any" />
        <% end %>
        <%= if @action == :transfer do %>
          <span>
            If the list is empty you need to
            <.link class="underline" navigate={~p"/gardens/#{@garden.id}/products/new"}>
              add growing media
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

        <%!-- <.input field={@form[:trimmed]} type="checkbox" label="Trimmed" /> --%>
        <:actions>
          <.button phx-disable-with="Saving...">Save Event log</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def highlight(assigns) do
    KeywordHighlighter.highlight(assigns.string, assigns.matches)
  end

  defp event_type_for_action(:new_water), do: "water"
  defp event_type_for_action(:new_water_bed), do: "water"
  defp event_type_for_action(:transfer), do: "transfer"
  defp event_type_for_action(:transfer_bed), do: "transfer"
  defp event_type_for_action(:till), do: "till"
  defp event_type_for_action(:till_bed), do: "till"

  @impl true
  def update(assigns, socket) do
    el = %EventLog{}

    changeset =
      Gardens.change_event_log(el, %{"event_type" => event_type_for_action(assigns.action)})

    product_opts =
      Enum.map(assigns.products, fn p ->
        %{label: p.name, value: to_string(p.id), matches: []}
      end)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       :product_opts,
       product_opts
     )
     |> assign(
       :product_opts_all,
       product_opts
     )
     |> assign(:event_log, el)
     |> assign_form(changeset)}
  end

  @impl true
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

  def handle_event("validate", %{"event_log" => event_log_params}, socket) do
    changeset =
      socket.assigns.event_log
      |> Gardens.change_event_log(
        merge_attrs(event_log_params, socket.assigns.action, socket.assigns.product)
      )
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"event_log" => event_log_params}, socket) do
    save_event_log(socket, socket.assigns.action, event_log_params)
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

  # defp save_event_log(socket, :edit, event_log_params) do
  #   case Gardens.update_event_log(socket.assigns.event_log, event_log_params) do
  #     {:ok, event_log} ->
  #       notify_parent({:saved, event_log})

  #       {:noreply,
  #        socket
  #        |> put_flash(:info, "Event log updated successfully")
  #        |> push_patch(to: socket.assigns.patch)}

  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       {:noreply, assign_form(socket, changeset)}
  #   end
  # end

  defp save_event_log(socket, :transfer, event_log_params) do
    if event_log_params["transferred_from_id"] not in Enum.map(
         socket.assigns.products,
         &to_string(&1.id)
       ) do
      raise UnauthorizedError
    else
      do_save_event_log(socket, "transfer", event_log_params)
    end
  end

  defp save_event_log(socket, :new_water, event_log_params) do
    do_save_event_log(socket, "water", event_log_params)
  end

  defp save_event_log(socket, :till, event_log_params) do
    do_save_event_log(socket, "till", event_log_params)
  end

  defp do_save_event_log(socket, type, event_log_params) do
    Authorization.authorize_garden_modify(socket.assigns.garden.id, socket.assigns.current_user)

    case Gardens.create_event_log(
           type,
           merge_attrs(event_log_params, socket.assigns.action, socket.assigns.product)
         ) do
      {:ok, event_log} ->
        notify_parent({:saved, VisualGarden.Repo.preload(event_log, :transferred_from)})

        {:noreply,
         socket
         |> put_notification(Normal.new(:info, "Event log created successfully"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
