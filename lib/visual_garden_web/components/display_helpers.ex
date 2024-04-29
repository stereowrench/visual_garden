defmodule VisualGardenWeb.DisplayHelpers do
  alias VisualGarden.Library.Species
  use Phoenix.Component

  @spec species_display_string(%Species{}) :: any()
  def species_display_string(species) do
    assigns = %{
      genus: species.genus,
      variant: species.variant,
      name: species.name,
      cultivar: species.cultivar
    }

    var_str =
      case assigns.variant do
        nil -> ""
        var -> " var. #{var}"
      end

    cultivar_str =
      case assigns.cultivar do
        nil -> ""
        cv  -> "'#{cv}'"
      end

    assigns = put_in(assigns[:var_str], var_str)
    assigns = put_in(assigns[:cultivar_str], cultivar_str)

    ~H"""
    <i><%= @genus %> <%= @name %> <%= @var_str %></i><%= @cultivar_str %>
    """
  end
end
