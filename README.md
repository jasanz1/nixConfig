# NixOS Modular Configuration

This NixOS configuration follows a modular architecture designed for maintainability, reusability, and multi-host support. The structure separates concerns into logical modules, profiles, and host-specific configurations.

## Quick Start

### Building Your System
```bash
# Build and switch to the new configuration
sudo nixos-rebuild switch --flake .#thonkpad

# Build without switching (for testing)
sudo nixos-rebuild build --flake .#thonkpad

# Update flake inputs
nix flake update
```

### Adding a New Host
```bash
# 1. Create host directory
mkdir -p hosts/newhostname

# 2. Copy template files
cp hosts/thonkpad/configuration.nix hosts/newhostname/
cp hosts/thonkpad/users.nix hosts/newhostname/

# 3. Generate hardware configuration
sudo nixos-generate-config --dir hosts/newhostname

# 4. Edit configuration files to match new host
# 5. Add host to flake.nix
```

### Adding a New User
```bash
# 1. Copy user template
cp -r users/templates users/newusername

# 2. Rename template files
cd users/newusername
mv default-user.nix default.nix
mv default-system.nix system.nix
mv default-home.nix home.nix

# 3. Customize user configuration
# 4. Import user in host configuration
```

## Directory Structure

```
/etc/nixos/
├── flake.nix                 # Main flake with host definitions and outputs
├── flake.lock               # Locked flake inputs for reproducibility
├── hosts/                   # Host-specific configurations
│   └── thonkpad/           # Example host configuration
│       ├── configuration.nix # Host-specific system settings
│       ├── hardware.nix     # Hardware-specific configuration
│       └── users.nix        # Host-specific user assignments
├── modules/                 # Reusable system modules
│   ├── desktop/            # Desktop environment modules
│   │   ├── default.nix     # Desktop module defaults
│   │   └── hyprland.nix    # Hyprland window manager configuration
│   ├── development/        # Development tools and environments
│   │   ├── default.nix     # Development module defaults
│   │   ├── languages.nix   # Programming language support
│   │   └── tools.nix       # Development tools and utilities
│   ├── networking/         # Network configurations
│   │   └── default.nix     # Networking module defaults
│   ├── security/           # Security and authentication
│   │   └── default.nix     # Security module defaults
│   ├── services/           # System services
│   │   ├── default.nix     # Services module defaults
│   │   ├── docker.nix      # Docker containerization
│   │   └── openssh.nix     # SSH server configuration
│   └── system/             # Core system configuration
│       ├── default.nix     # System module defaults
│       └── packages.nix    # System-wide packages
├── profiles/               # Pre-configured system profiles
│   ├── desktop.nix         # Complete desktop workstation setup
│   ├── server.nix          # Headless server configuration
│   └── minimal.nix         # Minimal system with essential tools only
├── users/                  # User-specific configurations
│   ├── jacob/              # Example user configuration
│   │   ├── default.nix     # Main user module
│   │   ├── home.nix        # Home Manager configuration
│   │   └── system.nix      # System-level user settings
│   └── templates/          # User configuration templates
│       ├── README.md       # Template usage instructions
│       ├── default-user.nix    # Main user template
│       ├── default-system.nix  # System user template
│       └── default-home.nix    # Home Manager template
├── lib/                    # Helper functions and utilities
│   └── default.nix         # Library functions for configuration
└── scripts/                # Validation and migration scripts
    ├── validate-config.sh   # Configuration validation
    ├── validate-structure.sh # Directory structure validation
    ├── compare-configurations.sh # Configuration comparison
    └── test-migration.sh    # Migration testing
```

## Architecture Overview

### Modules
Modules are reusable configuration components that can be shared across hosts:

- **Desktop Modules**: Window managers, display managers, desktop applications
- **Development Modules**: Programming languages, development tools, IDEs
- **Networking Modules**: Network configuration, VPN, firewall settings
- **Security Modules**: Authentication, encryption, access control
- **Services Modules**: System services like Docker, SSH, printing
- **System Modules**: Core system packages and configuration

Each module provides:
- Enable/disable options for fine-grained control
- Sensible defaults that can be overridden
- Clear separation of concerns
- Documentation of configuration options

### Profiles
Profiles combine multiple modules for common use cases:

- **Desktop Profile**: Complete workstation with GUI, development tools, and desktop applications
- **Server Profile**: Headless server with essential services and security hardening
- **Minimal Profile**: Basic system with only essential tools

### Hosts
Each host has its own directory containing:
- `configuration.nix`: Host-specific settings (hostname, timezone, locale)
- `hardware.nix`: Hardware-specific configuration (generated by nixos-generate-config)
- `users.nix`: Host-specific user definitions and assignments

### Users
User configurations are separated from system configuration:
- Each user has their own directory under `users/`
- System-level user settings (account, groups, system packages)
- Home Manager configurations for user environment and dotfiles
- Templates available for creating new users

## Configuration Examples

### Enabling/Disabling Modules
```nix
# In your host configuration
modules.development = {
  languages = {
    enable = true;
    rust.enable = true;
    python.enable = true;
    nodejs.enable = false;  # Disable Node.js
  };
  tools = {
    enable = true;
    git.enable = true;
    containers.enable = true;
  };
};
```

### Host-Specific Overrides
```nix
# In hosts/hostname/configuration.nix
{
  # Use desktop profile but override specific settings
  imports = [ ../../profiles/desktop.nix ];
  
  # Host-specific overrides
  networking.hostName = "my-workstation";
  time.timeZone = "America/New_York";
  
  # Disable specific desktop features for this host
  modules.desktop.hyprland.enable = false;
  services.xserver.desktopManager.gnome.enable = true;
}
```

### Adding Custom Packages
```nix
# In your host configuration or user configuration
environment.systemPackages = with pkgs; [
  # Add custom packages here
  my-custom-package
];

# Or in user home configuration
home.packages = with pkgs; [
  # User-specific packages
  user-specific-tool
];
```

## Validation and Testing

The configuration includes validation scripts to ensure correctness:

```bash
# Validate directory structure
./scripts/validate-structure.sh

# Validate configuration syntax
./scripts/validate-config.sh

# Compare configurations (useful during migration)
./scripts/compare-configurations.sh

# Test migration process
./scripts/test-migration.sh
```

## Migration from Monolithic Configuration

This configuration was migrated from a monolithic setup. The migration process:

1. **Backup**: Original configuration backed up to `backup-YYYY-MM-DD-HHMM/`
2. **Modularization**: Configuration split into logical modules
3. **Host Separation**: Host-specific settings moved to `hosts/` directory
4. **User Separation**: User configurations moved to `users/` directory
5. **Profile Creation**: Common configurations grouped into profiles
6. **Validation**: Scripts created to ensure functional equivalence

## Troubleshooting

### Common Issues

**Build Failures**
```bash
# Check for syntax errors
nix flake check

# Build with verbose output
sudo nixos-rebuild switch --flake .#hostname --show-trace
```

**Module Not Found**
- Ensure module is imported in the appropriate `default.nix`
- Check file paths and naming conventions
- Verify module exports the expected options

**User Configuration Issues**
- Ensure user is defined in `users.nix` for the host
- Check Home Manager configuration syntax
- Verify user has appropriate permissions

### Getting Help

1. Check the NixOS manual: https://nixos.org/manual/nixos/stable/
2. Review module documentation in each module file
3. Use `nix repl` to explore configuration options
4. Check the NixOS discourse: https://discourse.nixos.org/

## Contributing

When adding new modules or features:

1. Follow the existing directory structure
2. Use consistent naming conventions
3. Provide enable/disable options
4. Include documentation in module files
5. Test with validation scripts
6. Update this README if needed

## Backup and Recovery

- Original configuration backed up in `backup-YYYY-MM-DD-HHMM/`
- Use `nixos-rebuild switch --rollback` to revert to previous generation
- Keep flake.lock under version control for reproducibility
- Regular backups recommended for `/etc/nixos` directory