# System Profiles

This directory contains pre-configured system profiles that combine multiple modules for common use cases. Profiles provide a convenient way to set up complete system configurations with sensible defaults.

## Available Profiles

### Desktop Profile (`desktop.nix`)

Complete desktop workstation setup with GUI, development tools, and desktop applications.

#### Included Modules
- **Desktop**: Hyprland window manager, display management
- **Development**: Full development environment with multiple languages
- **System**: Complete system package set
- **Networking**: NetworkManager for desktop networking
- **Services**: Desktop-appropriate services

#### Features
- **GUI Environment**: Complete desktop environment with window manager
- **Audio Support**: PipeWire audio system with ALSA and PulseAudio compatibility
- **Bluetooth**: Bluetooth support for peripherals
- **Printing**: CUPS printing system with network printer discovery
- **Development**: Full development toolchain for multiple languages
- **Desktop Applications**: Web browser, office suite, media players
- **Fonts**: Comprehensive font collection including programming fonts

#### Use Cases
- Developer workstations
- General-purpose desktop computers
- Creative workstations
- Home computers with GUI needs

### Server Profile (`server.nix`)

Headless server configuration with essential services and security hardening.

#### Included Modules
- **System**: Essential system packages only
- **Services**: Server-appropriate services (SSH, etc.)
- **Security**: Security hardening and monitoring

#### Features
- **Headless Operation**: No GUI or desktop environment
- **Security Hardening**: Secure SSH configuration, firewall enabled
- **System Monitoring**: Logging and monitoring tools
- **Network Services**: Essential network services only
- **Minimal Footprint**: Only essential packages installed
- **Remote Management**: SSH access with key-based authentication

#### Use Cases
- Web servers
- Database servers
- Application servers
- Remote development servers
- Infrastructure services

### Minimal Profile (`minimal.nix`)

Basic system with only essential tools and minimal resource usage.

#### Included Modules
- **System**: Basic system packages only (text editing, essential utilities)

#### Features
- **Minimal Installation**: Smallest possible system footprint
- **Essential Tools Only**: Basic text editors and system utilities
- **No Network Services**: No services enabled by default
- **Low Resource Usage**: Minimal memory and storage requirements
- **Basic Networking**: Simple DHCP networking only

#### Use Cases
- Embedded systems
- Containers and virtual machines
- Recovery systems
- Base systems for custom builds
- Resource-constrained environments

## Profile Comparison

| Feature | Desktop | Server | Minimal |
|---------|---------|--------|---------|
| GUI Environment | ✅ Hyprland | ❌ Headless | ❌ Headless |
| Development Tools | ✅ Full Suite | ❌ None | ❌ None |
| Audio Support | ✅ PipeWire | ❌ Disabled | ❌ Disabled |
| Bluetooth | ✅ Enabled | ❌ Disabled | ❌ Disabled |
| SSH Server | ⚠️ Optional | ✅ Enabled | ❌ Disabled |
| Printing | ✅ CUPS | ❌ Disabled | ❌ Disabled |
| NetworkManager | ✅ Enabled | ❌ DHCP Only | ❌ DHCP Only |
| System Packages | ✅ Complete | ⚠️ Essential | ⚠️ Minimal |
| Resource Usage | 🔴 High | 🟡 Medium | 🟢 Low |

## Usage Examples

### Using Desktop Profile
```nix
# In hosts/hostname/configuration.nix
{
  imports = [ ../../profiles/desktop.nix ];
  
  # Host-specific overrides
  networking.hostName = "my-workstation";
  
  # Profile is fully configured, minimal additional setup needed
}
```

### Using Server Profile
```nix
# In hosts/hostname/configuration.nix
{
  imports = [ ../../profiles/server.nix ];
  
  # Host-specific configuration
  networking.hostName = "my-server";
  
  # Enable additional services as needed
  services.nginx.enable = true;
  services.postgresql.enable = true;
}
```

### Using Minimal Profile
```nix
# In hosts/hostname/configuration.nix
{
  imports = [ ../../profiles/minimal.nix ];
  
  # Host-specific configuration
  networking.hostName = "minimal-system";
  
  # Add only what you need
  environment.systemPackages = with pkgs; [
    git  # Add git if needed
  ];
}
```

### Profile Customization

Profiles can be customized by overriding specific settings:

```nix
{
  imports = [ ../../profiles/desktop.nix ];
  
  # Disable specific desktop features
  modules.desktop.hyprland.enable = false;
  services.xserver.desktopManager.gnome.enable = true;
  
  # Override development tools
  modules.development.languages.nodejs.enable = false;
  
  # Add custom packages
  environment.systemPackages = with pkgs; [
    my-custom-application
  ];
}
```

## Profile Selection Guidelines

### Choose Desktop Profile When:
- You need a GUI environment
- You're doing software development
- You need multimedia capabilities
- You want a complete workstation setup
- Resource usage is not a primary concern

### Choose Server Profile When:
- Running headless services
- Security is a primary concern
- You need remote management capabilities
- Running in a data center or cloud environment
- You want a hardened, minimal attack surface

### Choose Minimal Profile When:
- Building custom configurations from scratch
- Resource constraints are critical
- Running in containers or VMs
- Creating specialized appliances
- You need maximum control over installed components

## Creating Custom Profiles

To create a new profile:

1. Create a new `.nix` file in this directory
2. Import the required modules
3. Configure module options with appropriate defaults
4. Add profile-specific packages and services
5. Document the profile in this README

Example custom profile structure:
```nix
# profiles/custom.nix
{ config, lib, pkgs, ... }:

{
  imports = [
    ../modules/system
    ../modules/services
    # Add other required modules
  ];

  # Configure modules for this profile
  modules.system.packages = {
    enable = true;
    # Configure package categories
  };

  # Add profile-specific configuration
  services.myservice.enable = true;
  
  # Profile-specific packages
  environment.systemPackages = with pkgs; [
    # Custom package list
  ];
}
```

## Profile Migration

### From Monolithic to Profile-Based

When migrating from a monolithic configuration:

1. **Identify Use Case**: Determine which profile best matches your needs
2. **Start with Base Profile**: Import the closest matching profile
3. **Add Customizations**: Override settings as needed for your specific requirements
4. **Test Configuration**: Build and test the new configuration
5. **Iterate**: Refine the configuration based on testing results

### Between Profiles

To change from one profile to another:

1. **Backup Current Config**: Ensure you can rollback if needed
2. **Change Import**: Update the profile import in your host configuration
3. **Review Differences**: Check what changes between profiles
4. **Add Missing Features**: Explicitly enable any features you need that aren't in the new profile
5. **Test Thoroughly**: Ensure all required functionality works

## Troubleshooting

### Profile Not Working
- Check that all required modules are available
- Verify import paths are correct
- Review NixOS build errors for missing dependencies

### Missing Features
- Check if feature is included in the chosen profile
- Enable additional modules or services as needed
- Consider switching to a more comprehensive profile

### Resource Issues
- Monitor system resource usage
- Consider switching to a lighter profile
- Disable unnecessary features in current profile

### Conflicts Between Profiles
- Don't import multiple profiles simultaneously
- Use one profile as base and customize as needed
- Create custom profile if existing ones don't fit

## Getting Help

- Review individual module documentation
- Check NixOS manual for service configuration
- Use `nix repl` to explore configuration options
- Test configurations with `nixos-rebuild build` before switching