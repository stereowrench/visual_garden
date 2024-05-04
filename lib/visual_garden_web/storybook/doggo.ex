defmodule VisualGardenWeb.Storybook.Doggo do
  use PhoenixStorybook,
    otp_app: :my_app_web,
    content_path: Path.join(:code.priv_dir(:doggo), "/storybook"),
    title: "Doggo Storybook",
    css_path: "/assets/storybook.css",
    js_path: "/assets/storybook.js",
    sandbox_class: "my-app-web"
end
