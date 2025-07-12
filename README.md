# enmap
Abusing elixir's concurrency for good*

## Features

- **Multiple Protocol Support**: TCP and UDP scanning
- **Concurrent Scanning**: Configurable concurrency levels for fast scanning
- **Flexible Host Input**: Single host or comma-separated multiple hosts
- **Port Specification**: Individual ports, comma-separated lists, or ranges
- **Multiple Output Formats**: Console, JSON, and quiet modes
- **Configurable Timeouts**: Adjustable connection timeouts

## Installation

Ensure you have Elixir installed on your system, then build the project:

```bash
mix escript.build
```

## Usage

### Basic Usage

```bash
# Scan a single host with default ports
./enmap google.com

# Scan with explicit host flag
./enmap -H google.com
```

### Advanced Usage

```bash
# Scan specific ports
./enmap -H google.com -p 80,443,8080

# Scan a port range
./enmap -H google.com -r 1-1000

# Scan with custom concurrency and timeout
./enmap -H google.com -r 1-1000 -c 200 -t 5000

# Output results in JSON format
./enmap -H google.com -o json

# Scan multiple hosts
./enmap -H google.com,github.com,stackoverflow.com

# UDP scan with custom settings. 
# Note: service/port-specific probes not yet! Feel free to integrate on top
./enmap -H 192.168.1.1 -s udp -p 53,67,68 -c 50
```

## Command Line Options

| Option | Long Form | Description | Default |
|--------|-----------|-------------|---------|
| `-H` | `--hosts` | Target hosts to scan (comma-separated) | Required |
| `-s` | `--scan` | Scan protocol (tcp, udp) | tcp |
| `-p` | `--ports` | Comma-separated ports (e.g., 80,443,8080) | Common ports |
| `-r` | `--range` | Port range (e.g., 1-1000) | Common ports |
| `-t` | `--timeout` | Timeout in milliseconds | 7000 |
| `-c` | `--concurrency` | Max concurrent connections | 100 |
| `-o` | `--output` | Output format (console, json, quiet) | console |
| `-h` | `--help` | Show help message | - |

## Default Ports

When no ports are specified, the scanner will check these common ports:
- 20 (FTP Data)
- 21 (FTP Control)
- 22 (SSH)
- 23 (Telnet)
- 25 (SMTP)
- 53 (DNS)
- 80 (HTTP)
- 110 (POP3)
- 443 (HTTPS)
- 993 (IMAPS)
- 995 (POP3S)

## Output Formats

### Console Output (Default)
Human-readable output showing scan results with host and port status.

### JSON Output
Structured JSON output suitable for programmatic processing:
```bash
./enmap -H google.com -o json
```

### Standard CLI Output
Minimal output for automated scripts:
```bash
./enmap -H google.com
```

## Examples

### Network Discovery
```bash
# Scan common ports on local network
./enmap -H 192.168.1.1 -r 1-1000 -c 200

# Quick service discovery
./enmap -H target.example.com -p 21,22,23,25,53,80,110,143,443,993,995
```

### Web Server Scanning
```bash
# Check web services
./enmap -H example.com -p 80,443,8080,8443

# Comprehensive web port scan
./enmap -H example.com -r 8000-9000 -c 150
```

## Performance Tuning

- **Concurrency**: Increase `-c` for faster scanning, but be mindful of network limits
- **Timeout**: Reduce `-t` for faster scans of responsive hosts
- **Port Ranges**: Use specific ports instead of large ranges when possible (20-1000)

## Requirements

- Elixir 1.18+ (Lower version not _strictly_ supported)
- Network connectivity to target hosts
- Appropriate firewall permissions for scanning

