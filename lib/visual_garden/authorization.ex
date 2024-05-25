defmodule VisualGarden.Authorization do
  alias VisualGarden.Gardens

  defmodule UnauthorizedError do
    defexception message: "Unauthorized", plug_status: 401
  end

  def authorize_garden(id, user) do
    garden = Gardens.get_garden!(id)

    case garden.visibility do
      :public ->
        :ok

      :private ->
        if user == nil do
          raise UnauthorizedError
        end

        if garden.owner_id != user.id && user.role not in [:admin, :moderator] do
          raise UnauthorizedError
        end
    end
  end
end
