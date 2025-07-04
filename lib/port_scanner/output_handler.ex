defmodule PortScanner.OutputHandler do
  @callback scan_started(host :: String.t(), port_count :: integer(), opts :: keyword()) :: :ok
  @callback scan_completed(duration :: integer()) :: :ok
  @callback print_results(results :: list(), stats :: map()) :: :ok
end


defmodule PortScanner.ConsoleOutput do
  @behaviour PortScanner.OutputHandler
  
  def scan_started(host, port_count, opts) do
    max_concurrency = Keyword.get(opts, :max_concurrency, 100)
    timeout = Keyword.get(opts, :timeout, 1000)
    
    IO.puts("Starting scan of #{host} on #{port_count} ports...")
    IO.puts("Max concurrency: #{max_concurrency}, Timeout: #{timeout}ms")
  end
  
  def scan_completed(duration) do
    IO.puts("\nScan completed in #{duration}ms")
  end
  
  def print_results(results, stats) do
    IO.puts("\n" <> String.duplicate("=", 50))
    IO.puts("SCAN RESULTS")
    IO.puts(String.duplicate("=", 50))
    
    # Group results by status
    grouped = Enum.group_by(results, & &1.status)
    
    # Show open ports first
    if open_ports = grouped[:open] do
      IO.puts("\nOPEN PORTS (#{length(open_ports)}):")
      open_ports
      |> Enum.sort_by(& &1.port)
      |> Enum.each(fn result ->
        IO.puts("  #{result.host}:#{result.port}")
      end)
    end
    
    # Show closed ports summary
    if closed_ports = grouped[:closed] do
      IO.puts("\nCLOSED PORTS: #{length(closed_ports)}")
    end
    
    # Show timeout ports
    if timeout_ports = grouped[:timeout] do
      IO.puts("\nTIMEOUT PORTS: #{length(timeout_ports)}")
    end
    
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
end



defmodule PortScanner.JsonOutput do
  @behaviour PortScanner.OutputHandler
  
  def scan_started(host, port_count, opts) do
    Jason.encode!(%{
      event: "scan_started",
      host: host,
      port_count: port_count,
      options: Enum.into(opts, %{}) 
    })
    |> IO.puts()
  end
  
  def scan_completed(duration) do
    Jason.encode!(%{
      event: "scan_completed",
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

