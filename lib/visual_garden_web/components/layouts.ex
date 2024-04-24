defmodule VisualGardenWeb.Layouts do
  use VisualGardenWeb, :html

  embed_templates "layouts/*"

  attr :active, :atom, required: true
  attr :name, :atom, required: true
  attr :path, :string, required: true
  attr :text, :string, required: true
  def nav_link(%{} = assigns) do
    ~H"""
    <.link
      redirect={@path}
      class={(if @active == @name, do: "bg-gray-50 text-indigo-600", else: "text-gray-700 hover:text-indigo-600 hover:bg-gray-50") <> " group flex gap-x-3 rounded-md p-2 text-sm leading-6 font-semibold"}
    >
      <%= @text %>
    </.link>
    """
  end
end
