# Extravio Tools

A collection of networking and automation utilities for managing SSH connections, file transfers, and remote command execution across multiple hosts, with first-class support for Tailscale and Home Assistant.

## Features

- 🚀 **Quick SSH Access** - Connect to hosts using simple aliases with partial matching
- 📁 **Easy File Transfers** - Copy files to remote hosts with route aliases
- 🏠 **Home Assistant CLI** - Execute HA commands remotely with formatted output
- 🔐 **SSH Key Management** - Interactive key generation tool
- 🌐 **Tailscale Integration** - Automatic Tailscale connectivity management
- ⚙️ **Smart Routing** - Centralized JSON configuration for all connection targets
- 🔗 **Shell Completion** - Tab completion support for bash and zsh

## Installation

1. Clone this repository:
   ```bash
   git clone <repository-url> ~/bin/extravio_tools
   cd ~/bin/extravio_tools
   ```

2. Run the installer to add tools to your PATH:
   ```bash
   ./install.sh
   ```

3. Reload your shell:
   ```bash
   source ~/.bashrc  # or ~/.zshrc
   ```

## Tools Overview

### Routing Tools

#### `routeto` - SSH to Remote Hosts
Connect to configured hosts using simple aliases.

**Usage:**
```bash
routeto <route-alias>
routeto ha-primary      # SSH to primary Home Assistant
routeto pi-tailscale    # SSH to Raspberry Pi via Tailscale
routeto park-st-mac     # SSH to local Mac
```

**Features:**
- Automatic SSH agent management
- Tailscale connectivity when needed
- Connection timeout detection
- Error handling for common SSH issues
- Partial matching support (e.g., `routeto ha-p` matches `ha-prod`)
- Docker container support (executes `/bin/bash` in container for docker routes)

#### `file_copy` - Transfer Files
Copy files to remote hosts using route aliases.

**Usage:**
```bash
file_copy <route> <source> <destination>
file_copy ha-primary config.yaml /config/
file_copy pi-vtlander script.sh /home/user/scripts/
```

**Features:**
- Directory copy support (non-HA routes)
- Automatic destination directory creation
- Special handling for Home Assistant (uses SSH + sudo tee)
- SCP with timeout for other routes
- Partial matching for route aliases

#### `remote-ha` - Execute Home Assistant CLI Commands
Run Home Assistant CLI commands on remote instances with formatted output.

**Usage:**
```bash
remote-ha <route> <command> [args...]
remote-ha primary core info --raw
remote-ha backup supervisor reload
remote-ha primary addons list
```

**Features:**
- Shortened route names (e.g., `primary` instead of `ha-primary`)
- Automatic HA environment setup
- Box-formatted output for readability
- Exit code reporting
- Partial matching for route aliases

#### `remote-docker` - Execute Docker Container Commands
Run commands inside Docker containers on remote hosts using route aliases.

**Usage:**
```bash
remote-docker <route> <command> [args...]
remote-docker dev-ha-mac ls -la
remote-docker dev-ha-mac ps aux
```

**Features:**
- Docker container command execution on remote hosts
- Box-formatted output for readability
- Exit code reporting
- Partial matching for route aliases
- Only works with routes that have `hosttype: "docker"`

### Utility Tools

#### `create_ssh_key.sh` - SSH Key Generator
Interactive tool for generating SSH keys with modern defaults.

**Usage:**
```bash
./create_ssh_key.sh
```

**Supported Key Types:**
- `ed25519` (default, recommended)
- `rsa` (4096-bit default)
- `ecdsa`

**Features:**
- Interactive prompts with sensible defaults
- Automatic `.ssh` directory setup
- Optional passphrase protection
- Automatic comment generation
- GitHub configuration instructions

#### `git_init_repo` - GitHub Repository Initializer
Creates or clones GitHub repositories with automated setup.

**Usage:**
```bash
./git_init_repo
```

**Features:**
- SSH authentication check
- Creates repository if it doesn't exist
- Clones existing repositories
- Automatic initial commit and push

#### `list_dns` - Discover SSH Services
List SSH services on the local network using DNS-SD.

**Usage:**
```bash
list_dns
```

#### `install.sh` - PATH Installer
Adds all project directories to your shell PATH.

**Usage:**
```bash
./install.sh
```

Automatically detects bash or zsh and updates the appropriate config file. Includes setup for tab completion of route aliases.

## Configuration

### Adding Routes

Edit [`routing/routes.json`](routing/routes.json) to add new connection targets:

```json
{
  "my-server": {
    "username": "myuser",
    "hostroute": "hostname.example.com",
    "tailscale_required": "yes",
    "hosttype": "pc"
  },
  "local-machine": {
    "username": "user",
    "hostroute": "192.168.1.100",
    "tailscale_required": "no",
    "hosttype": "mac"
  },
  "dev-container": {
    "username": "user",
    "hostroute": "docker-host.example.com", 
    "dockercontainer": "my-dev-container",
    "tailscale_required": "no",
    "hosttype": "docker"
  }
}
```

The routes are automatically loaded by [`routing/get_routes.sh`](routing/get_routes.sh) which parses the JSON and provides both the legacy `get_address()` function and the new `get_route_field()` function for field-specific queries.

**Field Specifications:**
- `username` - SSH username (required)
- `hostroute` - Hostname, IP address, or FQDN (required)  
- `tailscale_required` - "yes" or "no" (defaults to "no" if absent)
- `hosttype` - "ha", "pi", "mac", "pc", "docker", "unknown" (defaults to "unknown" if absent)
- `dockercontainer` - Docker container name (required for `hosttype: "docker"`)

### Current Routes

| Alias | Description | Tailscale Required |
|-------|-------------|-------------------|
| `ha-primary` | Primary Home Assistant instance | Yes |
| `ha-backup` | Backup Home Assistant instance | Yes |
| `park-st-mac` | Mac at Park Street (local) | No |
| `pi-tailscale` | Raspberry Pi via Tailscale | Yes |
| `pi-vtlander` | Raspberry Pi on local network | Yes |

## Requirements

- **bash** 3.2 or later (macOS compatible)
- **jq** - JSON parser (install with `brew install jq`)
- **openssh** (ssh, scp, ssh-keygen)
- **tailscale** (optional, for Tailscale-enabled routes)
- **git** (for git_init_repo)
- **curl** (for git_init_repo)

## Examples

### Common Workflows

**1. Connect to Home Assistant:**
```bash
routeto ha-primary
```

**2. Check Home Assistant core info:**
```bash
remote-ha primary core info --raw
```

**3. Copy configuration to Home Assistant:**
```bash
file_copy ha-primary my-config.yaml /config/
```

**4. Generate a new SSH key:**
```bash
./create_ssh_key.sh
# Follow prompts to create ed25519 key
```

**5. Initialize a new GitHub repository:**
```bash
./git_init_repo
# Enter repo name and access token when prompted
```

## How It Works

### SSH Agent Management
The routing tools automatically manage SSH agent lifecycle:
- Starts `ssh-agent` if not running
- Loads all SSH keys from `~/.ssh/`
- Maintains agent across tool invocations

### Tailscale Integration
For routes marked with `tailscale_required:"yes"`:
- Automatically runs `tailscale up` before connecting
- Ensures connectivity to Tailscale-only hosts
- Only activates when needed

For routes marked with `tailscale_required:"no"`:
- Uses direct/local connection
- By default, shows a note if Tailscale is active but not required
- Can optionally disable Tailscale when not needed (see Environment Variables)

### Environment Variables

- `EXTRAVIO_DISABLE_TAILSCALE_WHEN_NOT_NEEDED=yes` - Automatically disables Tailscale when connecting to routes that don't require it. **Warning:** This may affect other active Tailscale connections.

### Connection Testing
```bash
# Test connection with 5-second timeout
ssh -o BatchMode=yes -o ConnectTimeout=5 "$host" echo "connected"
# Proceed with interactive SSH if successful
```

### Home Assistant Special Handling
- Sources `/etc/profile.d/homeassistant.sh` for HA environment
- Disables pager (`PAGER=cat`)
- Properly escapes command arguments
- Formats output in readable boxes

## Troubleshooting

### SSH Agent Issues
If SSH connections fail with authentication errors:
```bash
# Manually start SSH agent and add keys
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519  # or your key file
```

### Tailscale Connection Issues
Ensure Tailscale is installed and authenticated:
```bash
tailscale status
tailscale up
```

### Route Not Found
List available routes:
```bash
routeto --help
file_copy --help
remote-ha  # (with no arguments)
```

### Permission Denied (file_copy)
For Home Assistant routes, files are copied with sudo. Ensure the remote user has sudo privileges.

## Security Notes

- SSH keys should be password-protected for production use
- Keep your GitHub personal access tokens secure
- The tools never store passwords or tokens
- SSH agent manages keys securely in memory

## Contributing

To add new functionality:
1. Follow existing patterns in `common.sh` and `routes.conf`
2. Maintain Bash 3.2 compatibility (for macOS)
3. Use proper error handling and timeouts
4. Add routes to the `keys` array when updating `routes.conf`

## License

This project is provided as-is for personal use.

## Author

David A. (a-1vtlander)
