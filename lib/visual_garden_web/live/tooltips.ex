defmodule VisualGardenWeb.Tooltips do
  use VisualGardenWeb, :live_view

  def home_title do
    "Home page — Task list"
  end

  def home_content do
    assigns = %{}

    ~H"""
    Welcome to the <em>task list</em>. You can view
    upcoming tasks here and todo items that need to be fixed.
    """
  end

  def planner_title do
    "Planner"
  end

  def planner_content(garden) do
    assigns = %{garden: garden}

    ~H"""
    On this page you can plan out when to plant your plants. The available options are drawn from
    <.link navigate={~p"/gardens/#{@garden.id}/seeds"}>your garden's seeds</.link>.

    Once schedules you will be reminded on the home page of:
    <ul>
      <li>When to nurse your plants</li>
      <li>When to plant your plants</li>
      <li>When to water your plants</li>
      <li>[In development] When to mulch your plants</li>
      <li>[In development] When to thin your plants</li>
      <li>[In development] When to weed your plants</li>
      <li>[In development] When to trim your plants</li>
      <li>[In development] When to harvest your plants</li>
    </ul>
    """
  end
end
