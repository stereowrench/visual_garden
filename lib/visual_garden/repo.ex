defmodule VisualGarden.Repo do
  use Ecto.Repo,
    otp_app: :visual_garden,
    adapter: Ecto.Adapters.Postgres
end
