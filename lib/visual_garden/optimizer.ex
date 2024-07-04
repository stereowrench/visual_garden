defmodule VisualGarden.Optimizer do
  def run_optimize() do
    path = [:code.priv_dir(:visual_garden), "python"] |> Path.join()
    {:ok, pid} = :python.start([{:python_path, to_charlist(path)}])

    :python.call(pid, :optimize_iter, :register_handler, [self(), pid])
    # :python.cast(pid, {:register, self()})

    Task.async(fn ->
      Process.sleep(5_000)
      :python.stop(pid)
    end)

    plants = %{
      tomato: %{
        footprint: [1, 1],
        quantity: 4,
        staggered: false,
        planting_types: ["seed", "transplant"],
        spacing: 1
      }
    }
    |> Jason.encode!()

    planting_windows = %{
      tomato: [
        # seed
        [
          [[[1, 30]], [[1, 30]]],
          [[[1, 30]], [[1, 30]]]
        ],
        # transplant
        [
          [[[5, 35]], [[5, 35]]],
          [[[5, 35]], [[5, 35]]]
        ]
      ]
    }
    |> Jason.encode!()

    num_rows = 2
    num_columns = 2

    slot_duration = 7
    max_iterations = 100

    :python.cast(
      pid,
      {:run_optimization,
       [
         plants,
         planting_windows,
         num_rows,
         num_columns,
         slot_duration,
         max_iterations
       ]}
    )

    do_receive(pid)
    # grid
  end

  defp do_receive(pid) do
    receive do
      # x ->
      #   IO.puts("catch all")
      #   IO.inspect(x)
      #   IO.inspect(pid)
      #   do_receive(pid)
      # {:python, ^pid, foo} ->
      #   IO.puts("received")
      #   IO.inspect(foo)

      {:python, ^pid, {:status, iter, max_iter}} ->
        # Print the progress update
        IO.write("\r#{iter}/#{max_iter}")
        do_receive(pid)

      {:python, ^pid, {:stdout, data}} ->
        # Print the progress update
        IO.write("\r#{data}")
        do_receive(pid)

      {:python, ^pid, {:result, result}} ->
        result = Jason.decode!(result)
        IO.write("\n")
        IO.inspect(result)
        :python.stop(pid)
    after
      1_000 ->
        IO.puts("timed out")
    end
  end
end
