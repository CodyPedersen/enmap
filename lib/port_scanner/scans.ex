defprotocol PortScanner.Scan do
  @doc "Scan a single port using the specified scan"
  def scan_port(scan, host, port, timeout)

  @doc "Scan repr"
  def name(scan)
end


defmodule PortScanner.Scan.TCP do
  defstruct []
  
  defimpl PortScanner.Scan do
    def scan_port(_scan, host, port, timeout) do
      host_charlist = to_charlist(host)
      
      case :gen_tcp.connect(host_charlist, port, [], timeout) do
        {:ok, socket} ->
          :gen_tcp.close(socket)
          :open
        
        {:error, :timeout} ->
          :unknown
        
        {:error, _reason} ->
          :closed
      end
    end
    
    def name(_scan), do: :tcp
  end

  defimpl Jason.Encoder, for: PortScanner.Scan.TCP do
    def encode(scan, opts) do
      PortScanner.Scan.name(scan) |> Jason.Encoder.encode(opts)
    end
  end
end


defmodule PortScanner.Scan.UDP do
  defstruct []
  
  defimpl PortScanner.Scan do
    def scan_port(_scan, host, port, timeout) do
      host_charlist = to_charlist(host)
      
      case :gen_udp.open(0, [:binary, {:active, false}]) do
        {:ok, socket} ->
          result = scan_udp_port(socket, host_charlist, port, timeout)
          :gen_udp.close(socket)
          result
        
        {:error, _reason} ->
          :closed
      end
    end
    
    def name(_scan), do: :udp
    
    defp scan_udp_port(socket, host, port, timeout) do
      case :gen_udp.send(socket, host, port, <<>>) do
        :ok ->
          # Wait for response or ICMP unreachable
          case :gen_udp.recv(socket, 0, timeout) do
            {:ok, _data} ->
              :open
            
            {:error, :timeout} ->
              :unknown  # open or filtered
            
            {:error, _reason} ->
              :closed
          end
        
        {:error, _reason} ->
          :closed
      end
    end
  end

  defimpl Jason.Encoder, for: PortScanner.Scan.UDP do
    def encode(scan, opts) do
      PortScanner.Scan.name(scan) |> Jason.Encoder.encode(opts)
    end
  end

end
