defmodule VisualGarden.Authorization do
  alias VisualGarden.Gardens

  defmodule UnauthorizedError do
    defexception message: "Unauthorized", plug_status: 401
  end

  def can_modify_library?(user) do
    user.role == :admin
  end

  def authorize_library(user) do
    unless can_modify_library?(user) do
      raise UnauthorizedError
    end
  end

  def authorize_garden_view(id, user) do
    garden = Gardens.get_garden!(id)

    case garden.visibility do
      :public ->
        :ok

      :private ->
        unless can_modify_garden?(garden, user) do
          raise UnauthorizedError
        end
    end
  end

  def authorize_garden_modify(id, user) do
    garden = Gardens.get_garden!(id)

    unless can_modify_garden?(garden, user) do
      raise UnauthorizedError
    end
  end

  def can_modify_garden?(garden, user) do
    if user == nil do
      false
    else
      if garden.owner_id != user.id && user.role not in [:admin, :moderator] &&
           !Gardens.get_garden_user(garden, user) do
        false
      else
        true
      end
    end
  end
end
