defmodule VisualGardenWeb.Nav do
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

        {sv, _}
        when sv in [
               GardenLive.Index,
               GardenLive.Show,
               ProductLive.Show,
               ProductLive.Index,
               SeedLive.Index,
               SeedLive.Show,
               PlantLive.Index,
               PlantLive.Show
             ] ->
          :gardens

        {sv, _} when sv in [PlannerLive.Show, PlannerLive.Index] ->
          :planer

        {_, _} ->
          nil
      end

    {:cont, assign(socket, active_tab: active_tab)}
  end
end
