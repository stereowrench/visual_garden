defmodule VisualGarden.Repo.Migrations.AddUsersToGardens do
  use Ecto.Migration

  def change do
    create table(:garden_users) do
      add :garden_id, references(:gardens)
      add :user_id, references(:users)

      timestamps(type: :utc_datetime)
    end
  end
end
