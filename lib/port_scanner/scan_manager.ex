defmodule PortScanner.ScanManager do
  use GenServer
  
  # Client API
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{results: [], total_scanned: 0}, name: __MODULE__)
  end
  
  def add_result(host, port, status) do
    GenServer.cast(__MODULE__, {:result, host, port, status})
  end
  
  def get_results do
    GenServer.call(__MODULE__, :get_results)
  end
  
  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end
  
  def clear_results do
    GenServer.cast(__MODULE__, :clear)
  end
  
  # Server callbacks
  def init(state), do: {:ok, state}
  
  def handle_cast({:result, host, port, status}, state) do
    new_result = %{
      host: host, 
      port: port, 
      status: status, 
      timestamp: DateTime.utc_now()
    }
    
    new_state = %{
      results: [new_result | state.results],
      total_scanned: state.total_scanned + 1
    }
    
    IO.puts("[#{DateTime.utc_now() |> DateTime.to_time()}] #{host}:#{port} -> #{status}")
    {:noreply, new_state}
  end
  
  def handle_cast(:clear, _state) do
    {:noreply, %{results: [], total_scanned: 0}}
  end
  
  def handle_call(:get_results, _from, state) do
    {:reply, state.results, state}
  end
  
  def handle_call(:get_stats, _from, state) do
    open_ports = Enum.count(state.results, fn r -> r.status == :open end)
    closed_ports = Enum.count(state.results, fn r -> r.status == :closed end)
    
    stats = %{
      total_scanned: state.total_scanned,
      open_ports: open_ports,
      closed_ports: closed_ports,
      scan_time: get_scan_duration(state.results)
    }
    
    {:reply, stats, state}
  end
  
  defp get_scan_duration([]), do: 0
  defp get_scan_duration(results) do
    timestamps = Enum.map(results, & &1.timestamp)
    oldest = Enum.min(timestamps)
    newest = Enum.max(timestamps)
    DateTime.diff(newest, oldest, :millisecond)
  end
end


