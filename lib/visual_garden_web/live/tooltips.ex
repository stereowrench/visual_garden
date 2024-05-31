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
end
