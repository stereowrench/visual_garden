defmodule VisualGarden.Sentry do
  def filter_non_500(%Sentry.Event{original_exception: exception} = event) do
    cond do
      match?(%Bandit.HTTPError{}, exception) ->
        false

      match?(%{message: "Timeout waiting for space in the send_window"}, exception) ->
        false

      Plug.Exception.status(exception) < 500 ->
        false

      # Fall back to the default event filter.
      Sentry.DefaultEventFilter.exclude_exception?(exception, event.source) ->
        false

      true ->
        event
    end
  end
end
