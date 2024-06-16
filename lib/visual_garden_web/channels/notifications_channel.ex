defmodule VisualGardenWeb.NotificationsChannel do
  use VisualGardenWeb, :channel

  @impl true
  def join("notifications", payload, socket) do
    if authorized?(payload) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("subscribe", payload, socket) do
    bin = Jason.encode!(%{title: "update", body: "test", url: "/home"})
    WebPushElixir.send_notification(payload["sub"], bin)
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (notifications:lobby).
  @impl true
  def handle_in("shout", payload, socket) do
    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
