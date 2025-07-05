defmodule PortScanner do
  alias PortScanner.ScanManager
  
  def scan_hosts(hosts, ports, opts) do
    ScanManager.clear_results()
    
    output_handler = Keyword.get(opts, :output_handler, PortScanner.ConsoleOutput)
    output_handler.on_start(
      Enum.join(hosts,","),
      length(ports),
      opts
    )
    
    start_time = System.monotonic_time(:millisecond)
    Task.Supervisor.async_stream(
      PortScanner.ScanTaskSupervisor,
      hosts,
      fn host -> PortScanner.scan_host(host, ports, opts) end
    ) |> Stream.run()

    end_time = System.monotonic_time(:millisecond)
    duration = end_time - start_time
    
    output_handler.on_complete(duration)
    print_results(output_handler)
  end

  def scan_host(host, ports, opts \\ []) do
    max_concurrency = Keyword.get(opts, :max_concurrency, 100)
    timeout = Keyword.get(opts, :timeout, 1000)
    
    Task.Supervisor.async_stream(
      PortScanner.ScanTaskSupervisor,
      ports,
      fn port -> scan_single_port(host, port, timeout) end,
      max_concurrency: max_concurrency,
      timeout: timeout + 500
    )
    |> Stream.run()
  end
  
  defp scan_single_port(host, port, timeout) do
    host_charlist = to_charlist(host)
    
    case :gen_tcp.connect(host_charlist, port, [], timeout) do
      {:ok, socket} ->
        :gen_tcp.close(socket)
        ScanManager.add_result(host, port, :open)
        {port, :open}
      
      {:error, :timeout} ->
        ScanManager.add_result(host, port, :timeout)
        {port, :timeout}
      
      {:error, _reason} ->
        ScanManager.add_result(host, port, :closed)
        {port, :closed}
    end
  end
  
  defp print_results(output_handler) do
    results = ScanManager.get_results()
    stats = ScanManager.get_stats()
    
    output_handler.print_results(results, stats)
  end
end


defmodule PortScanner.Application do
  use Application
  
  def start(_type, _args) do
    PortScanner.ScannerSupervisor.start_link([])
  end
end
