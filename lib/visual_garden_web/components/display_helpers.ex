defmodule VisualGardenWeb.DisplayHelpers do
  alias VisualGarden.Library.Species
  use Phoenix.Component

  defp species_assigns(species) do
    assigns = %{
      genus: species.genus,
      variant: species.variant,
      name: species.name,
      cultivar: species.cultivar,
      common_name: species.common_name
    }

    var_str =
      case assigns.variant do
        nil -> ""
        var -> " var. #{var}"
      end

    cultivar_str =
      case assigns.cultivar do
        nil -> ""
        cv  -> " '#{cv}'"
      end

    common_str =
      case assigns.common_name do
        nil -> ""
        cn -> " (#{cn})"
      end

    assigns = put_in(assigns[:var_str], var_str)
    assigns = put_in(assigns[:cultivar_str], cultivar_str)
    assigns = put_in(assigns[:common_str], common_str)
  end

  @spec species_display_string(%Species{}) :: any()
  def species_display_string(species) do
    assigns = species_assigns(species)
    ~H"""
    <i><%= @genus %> <%= @name %> <%= @var_str %></i> <%= @cultivar_str %> <%= @common_str %>
    """
  end

  @spec species_display_string_simple(%Species{}) :: String.t()
  def species_display_string_simple(species) do
    assigns = species_assigns(species)
    """
    #{assigns.genus} #{assigns.name}#{assigns.var_str}#{assigns.cultivar_str}#{assigns.common_str}
    """
  end
end
