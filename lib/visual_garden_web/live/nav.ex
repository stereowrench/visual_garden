defmodule VisualGardenWeb.Nav do
  alias VisualGardenWeb.LibrarySeedLive
  alias VisualGardenWeb.GenusLive
  alias VisualGardenWeb.PlannerLive
  alias VisualGardenWeb.RegionLive
  alias VisualGardenWeb.SpeciesLive
  alias VisualGardenWeb.PlantLive
  alias VisualGardenWeb.SeedLive
  use VisualGardenWeb, :live_view

  alias VisualGardenWeb.ProductLive
  alias VisualGardenWeb.GardenLive

  def on_mount(:default, _params, _session, socket) do
    {:cont,
     socket
     |> attach_hook(:active_tab, :handle_params, &set_active_tab/3)}
  end

  defp set_active_tab(_params, _url, socket) do
    active_tab =
      case {socket.view, socket.assigns.live_action} do
        {GardenLive.Index, _} ->
          :gardens

        {GardenLive.Show, _} ->
          :garden_overview

        {ProductLive.Index, _} ->
          :media

        {ProductLive.Show, _} ->
          :media

        {PlannerLive.Show, _} ->
          :planner

        {SeedLive.Index, _} ->
          :plantables


        {SeedLive.Show, _} ->
          :plantables

        {PlantLive.Index, _} ->
          :plants

        {PlantLive.Show, _} ->
          :plants

        {RegionLive.Show, :garden_show} ->
          :planner

        {LibrarySeedLive.Index, :garden_library} ->
          :plantables


        {LibrarySeedLive.Show, :garden_library} ->
          :plantables

        {sv, _}
        when sv in [
               SpeciesLive.Index,
               SpeciesLive.Show,
               RegionLive.Show,
               RegionLive.Index,
               GenusLive.Index,
               GenusLive.Show,
               ScheduleLive.Index,
               ScheduleLive.Show
             ] ->
          :library

        {sv, _} when sv in [HomeLive.Show] ->
          :home

        {_, _} ->
          nil
      end

    {:cont, assign(socket, active_tab: active_tab)}
  end
end
