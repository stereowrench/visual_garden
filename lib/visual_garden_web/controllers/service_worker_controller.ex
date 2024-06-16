defmodule VisualGardenWeb.ServiceWorkerController do
  use VisualGardenWeb, :controller

  # https://elixirforum.com/t/pre-caching-assets-with-a-service-worker/31839?u=hunterboerner
  def service_worker(conn, _params) do
    conn
    |> put_resp_content_type("application/javascript")
    |> render("service_worker.js")
  end
end
