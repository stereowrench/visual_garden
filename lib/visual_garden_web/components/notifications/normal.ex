defmodule VisualGardenWeb.Components.Notifications.Normal do
  @moduledoc false

  use VisualGardenWeb, :html

  use Flashy.Normal, types: [:info, :success, :warning, :danger]

  import PetalComponents.Alert

  attr :key, :string, required: true
  attr :notification, Flashy.Normal, required: true

  def render(assigns) do
    ~H"""
    <Flashy.Normal.render key={@key} notification={@notification}>
      <.alert
        with_icon
        close_button_properties={close_button_properties(@notification.options, @key)}
        color={color(@notification.type)}
        class="relative overflow-hidden"
      >
        <span><%= Phoenix.HTML.raw(@notification.message) %></span>

        <.progress_bar :if={@notification.options.dismissible?} id={"#{@key}-progress"} />
      </.alert>
    </Flashy.Normal.render>
    """
  end

  attr :id, :string, required: true

  defp progress_bar(assigns) do
    ~H"""
    <div id={@id} class="absolute bottom-0 left-0 h-1 bg-black/10" style="width: 0%" />
    """
  end

  defp color(type), do: to_string(type)

  defp close_button_properties(%{closable?: true}, key),
    do: ["phx-click": JS.exec("data-hide", to: "##{key}")]

  defp close_button_properties(%{closable?: false}, _), do: nil
end
