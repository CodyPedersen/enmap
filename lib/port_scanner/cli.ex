defmodule PortScanner.CLI do
  @moduledoc """
  Command line interface for Port Scanner
  """
  def main(args) do
    args
    |> parse_args()
    |> process()
  end
  
  defp parse_args(args) do
    {options, argv, _} = 
      OptionParser.parse(args,
        switches: [
          help: :boolean,
          hosts: :string,
          ports: :string,
          timeout: :integer,
          concurrency: :integer,
          output: :string,
          range: :string,
          scan: :string
        ],
        aliases: [
          h: :help,
          H: :hosts,
          p: :ports,
          t: :timeout,
          c: :concurrency,
          o: :output,
          r: :range,
          s: :scan
        ]
      )
    case {options, argv} do
      {[help: true], _} ->
        :help
      {options, []} when options != [] ->
        options
      {options, [hosts | _]} ->
        Keyword.put(options, :hosts, hosts)
      _ ->
        :help
    end
  end
  
  defp process(:help) do
    IO.puts """
    Port Scanner CLI
    Usage:
      portscan [options] <host>
      portscan -H <host> [options]
    Options:
      -H, --hosts <hosts>      Target hosts to scan
      -s, --scan <scan>        Scan Protocol (tcp, udp)
      -p, --ports <ports>      Comma-separated ports (e.g., 80,443,8080)
      -r, --range <range>      Port range (e.g., 1-1000)
      -t, --timeout <ms>       Timeout in milliseconds (default: 1000)
      -c, --concurrency <num>  Max concurrent connections (default: 100)
      -o, --output <format>    Output format: console, json, quiet (default: console)
      -h, --help               Show this help
    Examples:
      portscan google.com
      portscan -H google.com -p 80,443,8080
      portscan -H google.com -r 1-1000 -c 200 -o json
    """
  end
  
  defp process(options) do
    # Start the supervisor
    {:ok, _pid} = PortScanner.ScannerSupervisor.start_link([])
    
    hosts = Keyword.get(options, :hosts)
    unless hosts do
      IO.puts("Error: Host is required")
      System.halt(1)
    end
    hosts = get_hosts(options)
    ports = get_ports(options)
    timeout = Keyword.get(options, :timeout, 7000)
    concurrency = Keyword.get(options, :concurrency, 100)
    output_handler = get_output_handler(options)
    scan_str = Keyword.get(options, :scan)
    
    PortScanner.scan_hosts(hosts, ports, [
      max_concurrency: concurrency,
      timeout: timeout,
      output_handler: output_handler,
      scan: scan_str
    ])
  end

  defp get_hosts(options) do
    hosts_str = Keyword.get(options, :hosts)
    hosts_str |> String.split(",")
  end

  defp get_ports(options) do
    cond do
      ports_str = Keyword.get(options, :ports) ->
        ports_str
        |> String.split(",")
        |> Enum.map(&String.to_integer/1)
      
      range_str = Keyword.get(options, :range) ->
        [start_str, end_str] = String.split(range_str, "-", parts: 2)
        start_port = String.to_integer(start_str)
        end_port = String.to_integer(end_str)
        Enum.to_list(start_port..end_port)
      
      true ->
        [20, 21, 22, 23, 25, 53, 80, 110, 443, 993, 995]
    end
  end
  
  defp get_output_handler(options) do
    case Keyword.get(options, :output, "console") do
      "json" -> PortScanner.JsonOutput
      _ -> PortScanner.ConsoleOutput
    end
  end
end
