defmodule VisualGardenWeb.KeywordHighlighter do
  use VisualGardenWeb, :live_component

  def highlight(string, matches) do
    assigns = %{
      string: string,
      matches: matches
    }

    case matches do
      nil ->
        ~H"<%= @string %>"

      _ ->
        hs =
          0..(String.length(string) - 1)
          |> Enum.map(fn idx ->
            case idx in matches do
              true ->
                assigns = %{string: string, idx: idx}
                ~H"<b><%= String.at(@string, @idx) %></b>"

              false ->
                assigns = %{string: string, idx: idx}
                ~H"<%= String.at(@string, @idx) %>"
            end
          end)

        assigns = %{hs: hs}

        ~H"""
        <%= for h <- @hs do %><%= h %><% end %>
        """
    end
  end
end
