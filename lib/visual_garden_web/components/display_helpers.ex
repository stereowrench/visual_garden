defmodule VisualGardenWeb.DisplayHelpers do
  alias VisualGarden.Library.Species
  use Phoenix.Component

  defp species_assigns(species) do
    assigns = %{
      genus: species.genus,
      variant: species.variant,
      name: species.name,
      cultivar: species.cultivar,
      common_name: species.common_name,
      season: species.season
    }

    var_str =
      case assigns.variant do
        nil -> ""
        var -> " var. #{var}"
      end

    cultivar_str =
      case assigns.cultivar do
        nil -> ""
        cv -> " '#{cv}'"
      end

    common_str =
      case assigns.common_name do
        nil -> ""
        cn -> " (#{cn})"
      end

    season_str =
      case assigns.season do
        nil -> ""
        cn -> "[#{cn}] "
      end

    assigns = put_in(assigns[:var_str], var_str)
    assigns = put_in(assigns[:cultivar_str], cultivar_str)
    assigns = put_in(assigns[:season_str], season_str)
    put_in(assigns[:common_str], common_str)
  end

  @spec species_display_string(%Species{}) :: any()
  def species_display_string(species) do
    assigns = species_assigns(species)

    ~H"""
    <%= @season_str %><i><%= @genus %> <%= @name %> <%= @var_str %></i> <%= @cultivar_str %> <%= @common_str %>
    """
  end

  def species_display_string(species, name) do
    species
    |> Map.put(:common_name, name)
    |> species_display_string()
  end

  @spec species_display_string_simple(%Species{}) :: String.t()
  def species_display_string_simple(species) do
    assigns = species_assigns(species)

    """
    #{assigns.season_str} #{assigns.genus} #{assigns.name}#{assigns.var_str}#{assigns.cultivar_str}#{assigns.common_str}
    """
  end

  def species_display_string_simple(species, name) do
    species
    |> Map.put(:common_name, name)
    |> species_display_string_simple()
  end

  def visibility_badge(:public) do
    assigns = %{}

    ~H"""
    <span class="inline-flex items-center rounded-md bg-gray-50 px-2 py-1 text-xs font-medium text-gray-600 ring-1 ring-inset ring-gray-500/10">
      Public
    </span>
    """
  end

  def visibility_badge(:private) do
    assigns = %{}

    ~H"""
    <span class="inline-flex items-center rounded-md bg-blue-50 px-2 py-1 text-xs font-medium text-blue-700 ring-1 ring-inset ring-blue-700/10">
      Private
    </span>
    """
  end
end
