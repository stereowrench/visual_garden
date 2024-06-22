defmodule VisualGardenWeb.Router do
  use VisualGardenWeb, :router

  import VisualGardenWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {VisualGardenWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", VisualGardenWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :creation,
      on_mount: [
        {VisualGardenWeb.UserAuth, :ensure_authenticated},
        VisualGardenWeb.Nav,
        Flashy.Hook
      ] do
      live "/gardens/new", GardenLive.Index, :new
      live "/gardens/:id/show/edit", GardenLive.Show, :edit
      live "/gardens/:id/show/collab", GardenLive.Show, :collab

      live "/home/orphaned_nursery/:nursery_entry", HomeLive.Show, :orphaned_nursery
      live "/home/new_garden", HomeLive.Show, :new_garden
      live "/home/:garden_id/:bed_id/transfer", HomeLive.Show, :transfer
    end
  end

  scope "/", VisualGardenWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/privacy", PageController, :privacy

    live_session :routed,
      on_mount: [
        {VisualGardenWeb.UserAuth, :mount_current_user},
        VisualGardenWeb.Nav,
        Flashy.Hook
      ] do
      live "/home", HomeLive.Show, :show

      live "/gardens", GardenLive.Index, :index
      live "/gardens/:id/edit", GardenLive.Index, :edit

      live "/gardens/:id", GardenLive.Show, :show

      live "/gardens/:garden_id/products", ProductLive.Index, :index
      live "/gardens/:garden_id/beds", ProductLive.Index, :beds
      live "/gardens/:garden_id/products/new", ProductLive.Index, :new
      live "/gardens/:garden_id/products/new_bed", ProductLive.Index, :new_bed
      live "/gardens/:garden_id/products/:id/edit", ProductLive.Index, :edit
      live "/gardens/:garden_id/beds/:id/edit", ProductLive.Index, :edit_bed

      live "/gardens/:garden_id/products/:id", ProductLive.Show, :show
      live "/gardens/:garden_id/beds/:id", ProductLive.Show, :show

      live "/gardens/:garden_id/beds/:id/show/edit", ProductLive.Show, :edit
      live "/gardens/:garden_id/beds/:id/show/new_water", ProductLive.Show, :new_water
      live "/gardens/:garden_id/beds/:id/show/till", ProductLive.Show, :till
      live "/gardens/:garden_id/beds/:id/show/transfer", ProductLive.Show, :transfer

      # Bulk plant actions
      live "/gardens/:garden_id/beds/:id/show/bulk_weed", ProductLive.Show, :bulk_weed
      live "/gardens/:garden_id/beds/:id/show/bulk_trim", ProductLive.Show, :bulk_trim
      live "/gardens/:garden_id/beds/:id/show/bulk_harvest", ProductLive.Show, :bulk_harvest

      live "/gardens/:garden_id/products/:id/show/edit", ProductLive.Show, :edit
      live "/gardens/:garden_id/products/:id/show/new_water", ProductLive.Show, :new_water
      live "/gardens/:garden_id/products/:id/show/till", ProductLive.Show, :till
      live "/gardens/:garden_id/products/:id/show/transfer", ProductLive.Show, :transfer

      live "/gardens/:garden_id/beds/:product_id/plants", PlantLive.Index, :index
      live "/gardens/:garden_id/plants", PlantLive.Index, :index
      live "/gardens/:garden_id/plants/new", PlantLive.Index, :new
      live "/gardens/:garden_id/beds/:product_id/plants/new", PlantLive.Index, :new
      live "/gardens/:garden_id/beds/:product_id/plants/:id/edit", PlantLive.Index, :edit

      live "/gardens/:garden_id/beds/:product_id/plants/:id", PlantLive.Show, :show
      live "/gardens/:garden_id/beds/:product_id/plants/:id/show/edit", PlantLive.Show, :edit

      live "/gardens/:garden_id/beds/:id/:square", ProductLive.Show, :show_square

      live "/event_logs", EventLogLive.Index, :index
      live "/event_logs/new", EventLogLive.Index, :new
      live "/event_logs/:id/edit", EventLogLive.Index, :edit

      live "/event_logs/:id", EventLogLive.Show, :show
      live "/event_logs/:id/show/edit", EventLogLive.Show, :edit

      live "/harvests", HarvestLive.Index, :index
      live "/harvests/new", HarvestLive.Index, :new
      live "/harvests/:id/edit", HarvestLive.Index, :edit

      live "/harvests/:id", HarvestLive.Show, :show
      live "/harvests/:id/show/edit", HarvestLive.Show, :edit

      live "/gardens/:garden_id/seeds", SeedLive.Index, :index
      live "/gardens/:garden_id/seeds/new", SeedLive.Index, :new
      live "/gardens/:garden_id/seeds/:id/edit", SeedLive.Index, :edit

      live "/gardens/:garden_id/seeds/:id", SeedLive.Show, :show
      live "/gardens/:garden_id/seeds/:id/show/edit", SeedLive.Show, :edit
      live "/gardens/:garden_id/seeds/:id/show/archive", SeedLive.Show, :archive

      live "/schedules", ScheduleLive.Index, :index
      live "/schedules/new", ScheduleLive.Index, :new
      live "/schedules/:id/edit", ScheduleLive.Index, :edit

      live "/schedules/:id", ScheduleLive.Show, :show
      live "/schedules/:id/show/edit", ScheduleLive.Show, :edit

      live "/regions", RegionLive.Index, :index
      live "/regions/new", RegionLive.Index, :new
      live "/regions/:id/edit", RegionLive.Index, :edit

      live "/regions/:id", RegionLive.Show, :show
      live "/regions/:id/show/edit", RegionLive.Show, :edit

      live "/species", SpeciesLive.Index, :index
      live "/species/new", SpeciesLive.Index, :new
      live "/species/:id/edit", SpeciesLive.Index, :edit

      live "/species/:id", SpeciesLive.Show, :show
      live "/species/:id/show/edit", SpeciesLive.Show, :edit

      live "/planners", PlannerLive.Index, :index
      live "/planners/:garden_id", PlannerLive.Show, :show
      live "/planners/:garden_id/new_bed", PlannerLive.Show, :new_bed
      live "/planners/:garden_id/:bed_id/new", PlannerLive.Show, :new_bulk
      live "/planners/:garden_id/:bed_id/:square/new", PlannerLive.Show, :new
      live "/planners/:garden_id/:bed_id/:square/:entry/edit", PlannerLive.Show, :edit

      live "/library_seeds", LibrarySeedLive.Index, :index
      live "/library_seeds/new", LibrarySeedLive.Index, :new
      live "/library_seeds/:id/edit", LibrarySeedLive.Index, :edit
      live "/library_seeds/:id/copy/:garden_id", LibrarySeedLive.Index, :copy

      live "/library_seeds/:id", LibrarySeedLive.Show, :show
      live "/library_seeds/:id/show/edit", LibrarySeedLive.Show, :edit

      live "/gardens/:garden_id/nursery_entries", NurseryEntryLive.Index, :index
      # live "/gardens/:garden_id/nursery_entries/new", NurseryEntryLive.Index, :new
      # live "/gardens/:garden_id/nursery_entries/:id/edit", NurseryEntryLive.Index, :edit

      live "/gardens/:garden_id/nursery_entries/:id", NurseryEntryLive.Show, :show
      # live "/gardens/:garden_id/nursery_entries/:id/show/edit", NurseryEntryLive.Show, :edit
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", VisualGardenWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:visual_garden, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: VisualGardenWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", VisualGardenWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [
        {VisualGardenWeb.UserAuth, :redirect_if_user_is_authenticated},
        VisualGardenWeb.Nav,
        Flashy.Hook
      ] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", VisualGardenWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [
        {VisualGardenWeb.UserAuth, :ensure_authenticated},
        VisualGardenWeb.Nav,
        Flashy.Hook
      ] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end
  end

  scope "/", VisualGardenWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [
        {VisualGardenWeb.UserAuth, :mount_current_user},
        VisualGardenWeb.Nav,
        Flashy.Hook
      ] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
