defmodule VisualGardenWeb.Components.Notifications.Disconnected do
  @moduledoc false

  use VisualGardenWeb, :html

  use Flashy.Disconnected

  import PetalComponents.Alert

  attr :key, :string, required: true

  def render(assigns) do
    ~H"""
    <Flashy.Disconnected.render key={@key}>
      <.alert with_icon color="danger" heading="We can't find the internet">
        Attempting to reconnect <Heroicons.arrow_path class="ml-1 w-3 h-3 inline animate-spin" />
      </.alert>
    </Flashy.Disconnected.render>
    """
  end
end
