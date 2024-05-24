defmodule VisualGardenWeb.UserSessionController do
  use VisualGardenWeb, :controller

  alias VisualGarden.Accounts
  alias VisualGardenWeb.UserAuth

  def create(conn, %{"_action" => "registered"} = params) do
    create(conn, params, "Account created successfully!")
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    conn
    |> put_session(:user_return_to, ~p"/users/settings")
    |> create(params, "Password updated successfully!")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  defp create(conn, %{"user" => user_params}, info) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      conn
      |> Flashy.put_notification(Normal.new(:info, info))
      |> UserAuth.log_in_user(user, user_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> Flashy.put_notification(Normal.new(:danger, "Invalid email or password"))
      |> Flashy.put_notification(Normal.new(:warning, String.slice(email, 0, 160)))
      |> redirect(to: ~p"/users/log_in")
    end
  end

  def delete(conn, _params) do
    conn
    |> Flashy.put_notification(Normal.new(:info, "Logged out successfully."))
    |> UserAuth.log_out_user()
  end
end
