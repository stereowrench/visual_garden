defmodule VisualGardenWeb.Layouts do
  use VisualGardenWeb, :html

  embed_templates "layouts/*"

  attr :active, :atom, required: true
  attr :name, :atom, required: true
  attr :path, :string, required: true
  attr :text, :string, required: true
  attr :icon, :string, default: nil
  attr :todo, :string, default: nil

  def nav_link(%{} = assigns) do
    ~H"""
    <.link
      navigate={@path}
      class={(if @active == @name, do: "bg-eagle-100 text-mojo-600", else: "text-eagle-700 hover:text-mojo-600 hover:bg-eagle-100") <> " group flex gap-x-3 rounded-md p-2 text-sm leading-6 font-semibold"}
    >
      <%= if @icon do %>
        <.icon name={@icon} />
      <% end %>
      <%= @text %>
      <%= if @todo do %>
        <PC.badge color="warning" label={"Todo #{@todo}"} />
      <% end %>
    </.link>
    """
  end
end
