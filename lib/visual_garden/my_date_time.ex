defmodule VisualGarden.MyDateTime do
  if Mix.env() == :test do
    def utc_now do
      ~U[2023-06-06 20:38:10.071979Z]
    end

    def utc_today do
      ~D[2023-06-06]
    end
  else
    def utc_now do
      DateTime.utc_now()
    end

    def utc_today do
      Date.utc_today()
    end
  end
end
