defmodule PortScanner.OutputHandler do
  @callback on_start(host :: String.t(), port_count :: integer(), opts :: keyword()) :: :ok
  @callback on_complete(duration :: integer()) :: :ok
  @callback print_results(results :: list(), stats :: map()) :: :ok
end


defmodule PortScanner.ConsoleOutput do
  @behaviour PortScanner.OutputHandler
  
  def on_start(hosts, port_count, opts) do
    max_concurrency = Keyword.get(opts, :max_concurrency, 100)
    timeout = Keyword.get(opts, :timeout, 1000)
    
    IO.puts("Starting scan of #{hosts} on #{port_count} ports...")
    IO.puts("Max concurrency: #{max_concurrency}, Timeout: #{timeout}ms")
  end
  
  def on_complete(duration) do
    IO.puts("\nScan completed in #{duration}ms")
  end
  
  def print_results(results, stats) do
    IO.puts("\n" <> String.duplicate("=", 50))
    IO.puts("SCAN RESULTS")
    IO.puts(String.duplicate("=", 50))
    
    print_port_results(results)   
    
    # Show statistics
    IO.puts("\n" <> String.duplicate("-", 30))
    IO.puts("STATISTICS")
    IO.puts(String.duplicate("-", 30))
    IO.puts("Total scanned: #{stats.total_scanned}")
    IO.puts("Open ports: #{stats.open_ports}")
    IO.puts("Closed ports: #{stats.closed_ports}")
    IO.puts("Scan duration: #{stats.scan_time}ms")
    IO.puts(String.duplicate("=", 50))
  end

  def print_port_results(results) do
    categories = [:open, :closed, :unknown]
    categories
    |> Enum.each(fn type ->
      print_port_category(type, results)
    end)
  end

  def print_port_category(type, results) do
    grouped = Enum.group_by(results, & &1.status)
    type_ports = grouped[type]

    if type_ports do
      IO.puts("\U #{type} ports (#{length(type_ports)})")
      type_ports
      |> Enum.sort_by(fn result -> {result.host, result.port} end)
      |> Enum.each(fn result ->
        IO.puts("  #{result.host}:#{result.port}")
      end)
    end
  end
end



defmodule PortScanner.JsonOutput do
  @behaviour PortScanner.OutputHandler
  
  def on_start(host, port_count, opts) do
    Jason.encode!(%{
      event: "on_start",
      host: host,
      port_count: port_count,
      options: Enum.into(opts, %{}) 
    })
    |> IO.puts()
  end
  
  def on_complete(duration) do
    Jason.encode!(%{
      event: "on_complete",
      duration_ms: duration
    })
    |> IO.puts()
  end
  
  def print_results(results, stats) do
    Jason.encode!(%{
      event: "scan_results",
      results: results,
      statistics: stats
    }, pretty: true)
    |> IO.puts()
  end
end

