defmodule VisualGardenWeb.TempUserController do
  alias VisualGarden.Wizard
  use VisualGardenWeb, :controller

  def assign(conn, params) do
    redirect_url =
      if r = params["return"] do
        r
      else
        ~p"/"
      end

    if get_session(conn, "temp_user_id") do
      redirect(conn, external: redirect_url)
    else
      temp_user = Wizard.create_temp_user!()
      conn = put_session(conn, "temp_user_id", temp_user.id)
      redirect(conn, external: redirect_url)
    end
  end
end
