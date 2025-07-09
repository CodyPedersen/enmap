defmodule PortScanner do
  alias PortScanner.ScanManager
  alias PortScanner.Scan
  
  @task_supervisor_name PortScanner.ScanTaskSupervisor


  def scan_hosts(hosts, ports, opts) do
    ScanManager.clear_results()
    
    output_handler = Keyword.get(opts, :output_handler, PortScanner.ConsoleOutput)
    output_handler.on_start(
      Enum.join(hosts,","),
      length(ports),
      opts
    )
    
    Task.Supervisor.async_stream(
      @task_supervisor_name,
      hosts,
      fn host -> PortScanner.scan_host(host, ports, opts) end,
      timeout: 50000
    ) |> Stream.run()

    output_handler.on_complete(
      ScanManager.get_results(),
      ScanManager.get_stats() 
    )
  end
  
  def scan_host(host, ports, opts \\ []) do
    max_concurrency = Keyword.get(opts, :max_concurrency, 100)
    timeout = Keyword.get(opts, :timeout, 1000)
    scan = Keyword.get(opts, :scan)

    Task.Supervisor.async_stream(
      @task_supervisor_name,
      ports,
      fn port -> scan_single_port(scan, host, port, timeout) end,
      max_concurrency: max_concurrency,
      timeout: timeout + 500
    )
    |> Stream.run()
  end
  
  defp scan_single_port(scan, host, port, timeout) do
    result = Scan.scan_port(scan, host, port, timeout)
    ScanManager.add_result(host, port, result)
    {port, :closed}
  end
end


defmodule PortScanner.Application do
  use Application
  
  def start(_type, _args) do
    PortScanner.ScannerSupervisor.start_link([])
  end
end
