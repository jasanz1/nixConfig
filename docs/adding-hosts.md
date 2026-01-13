# Adding New Hosts

This guide explains how to add new hosts (machines) to your NixOS configuration.

## Overview

Each host in this configuration has its own directory under `hosts/` containing:
- `configuration.nix`: Host-specific system settings
- `hardware.nix`: Hardware-specific configuration
- `users.nix`: Host-specific user assignments

## Step-by-Step Process

### 1. Create Host Directory

```bash
# Replace 'newhostname' with your desired hostname
mkdir -p hosts/newhostname
```

### 2. Generate Hardware Configuration

On the target machine, generate the hardware configuration:

```bash
# Generate hardware configuration
sudo nixos-generate-config --dir /tmp/nixos-config

# Copy the hardware configuration to your host directory
cp /tmp/nixos-config/hardware-configuration.nix hosts/newhostname/hardware.nix
```

### 3. Create Host Configuration

Create `hosts/newhostname/configuration.nix`:

```nix
# hosts/newhostname/configuration.nix
{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware.nix
    ./users.nix
    ../../profiles/desktop.nix  # Choose appropriate profile
  ];

  # Host-specific configuration
  networking.hostName = "newhostname";
  
  # System configuration
  time.timeZone = "America/New_York";  # Set your timezone
  i18n.defaultLocale = "en_US.UTF-8";
  
  # Bootloader configuration (adjust based on your system)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  # Allow unfree packages if needed
  nixpkgs.config.allowUnfree = true;
  
  # System state version (don't change after initial installation)
  system.stateVersion = "24.05"; # Set to your NixOS version
}
```

### 4. Create User Configuration

Create `hosts/newhostname/users.nix`:

```nix
# hosts/newhostname/users.nix
{ config, lib, pkgs, ... }:

{
  imports = [
    ../../users/jacob  # Import existing users as needed
    # Add other users as needed
  ];

  # Host-specific user configuration
  users.users.jacob = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "docker" ];
    # Add host-specific user settings here
  };
  
  # Enable sudo for wheel group
  security.sudo.wheelNeedsPassword = false;  # Adjust based on security needs
}
```

### 5. Add Host to Flake

Edit `flake.nix` to include your new host:

```nix
{
  # ... existing configuration ...
  
  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    nixosConfigurations = {
      # Existing host
      thonkpad = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/thonkpad/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
          }
        ];
      };
      
      # New host
      newhostname = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";  # Adjust architecture if needed
        modules = [
          ./hosts/newhostname/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
          }
        ];
      };
    };
  };
}
```

### 6. Build and Test

Test the configuration before switching:

```bash
# Build the configuration (doesn't activate it)
sudo nixos-rebuild build --flake .#newhostname

# If build succeeds, switch to the new configuration
sudo nixos-rebuild switch --flake .#newhostname
```

## Host Configuration Options

### Profile Selection

Choose the appropriate profile for your host:

```nix
# Desktop workstation
imports = [ ../../profiles/desktop.nix ];

# Server
imports = [ ../../profiles/server.nix ];

# Minimal system
imports = [ ../../profiles/minimal.nix ];
```

### Common Host Settings

```nix
{
  # Network configuration
  networking = {
    hostName = "hostname";
    networkmanager.enable = true;  # For desktop/laptop
    # OR for servers:
    # dhcpcd.enable = true;
    # networkmanager.enable = false;
  };
  
  # Locale and timezone
  time.timeZone = "America/New_York";
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
  };
  
  # Bootloader (UEFI systems)
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };
  
  # OR for BIOS systems:
  # boot.loader.grub = {
  #   enable = true;
  #   device = "/dev/sda";  # Adjust device
  # };
}
```

### Module Customization

Override module settings for specific hosts:

```nix
{
  # Use desktop profile but customize
  imports = [ ../../profiles/desktop.nix ];
  
  # Disable specific features
  modules.development.languages.nodejs.enable = false;
  
  # Enable additional features
  services.docker.enable = true;
  
  # Add host-specific packages
  environment.systemPackages = with pkgs; [
    host-specific-package
  ];
}
```

## Architecture-Specific Considerations

### x86_64 Systems
```nix
# In flake.nix
system = "x86_64-linux";
```

### ARM64 Systems
```nix
# In flake.nix
system = "aarch64-linux";

# May need additional configuration in host config
nixpkgs.config.allowUnsupportedSystem = true;
```

### 32-bit Systems
```nix
# In flake.nix
system = "i686-linux";
```

## Special Host Types

### Virtual Machines

For VM hosts, add VM-specific configuration:

```nix
{
  # VM-specific settings
  virtualisation.vmware.guest.enable = true;  # For VMware
  # OR
  virtualisation.virtualbox.guest.enable = true;  # For VirtualBox
  
  # Optimize for VM
  services.spice-vdagentd.enable = true;  # For better VM integration
  services.qemuGuest.enable = true;       # For QEMU/KVM
}
```

### Laptops

For laptop hosts, add power management:

```nix
{
  # Laptop-specific configuration
  services.tlp.enable = true;  # Power management
  services.logind = {
    lidSwitch = "suspend";
    lidSwitchExternalPower = "lock";
  };
  
  # Wireless configuration
  networking.wireless.enable = false;  # Use NetworkManager instead
  networking.networkmanager.enable = true;
}
```

### Servers

For server hosts, focus on security and remote management:

```nix
{
  imports = [ ../../profiles/server.nix ];
  
  # Server-specific security
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 80 443 ];  # Adjust as needed
  };
  
  # Remote management
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };
  
  # Monitoring
  services.prometheus.exporters.node.enable = true;
}
```

## Validation and Testing

### Pre-deployment Validation

```bash
# Check flake syntax
nix flake check

# Build configuration without switching
sudo nixos-rebuild build --flake .#newhostname

# Test in VM (if supported)
nixos-rebuild build-vm --flake .#newhostname
```

### Post-deployment Testing

```bash
# Verify system information
hostnamectl
systemctl status
journalctl -b  # Check boot logs

# Test network connectivity
ping google.com
systemctl status NetworkManager  # or dhcpcd

# Verify services
systemctl list-units --failed
```

## Troubleshooting

### Common Issues

**Build Failures**
- Check hardware.nix syntax
- Verify all imports exist
- Check for typos in configuration

**Boot Issues**
- Verify bootloader configuration matches hardware
- Check hardware.nix for correct disk references
- Ensure boot partition is properly configured

**Network Issues**
- Verify network configuration matches hardware
- Check if NetworkManager conflicts with other network services
- Ensure firewall allows necessary traffic

**User Issues**
- Verify user imports are correct
- Check user group memberships
- Ensure Home Manager configuration is valid

### Getting Help

- Check NixOS manual: https://nixos.org/manual/nixos/stable/
- Review hardware-configuration.nix comments
- Use `nixos-option` to explore configuration options
- Check system logs: `journalctl -b`

## Best Practices

1. **Test Before Deploying**: Always build and test configurations before switching
2. **Use Descriptive Names**: Choose clear, descriptive hostnames
3. **Document Customizations**: Comment unusual or host-specific configurations
4. **Keep Hardware Config Separate**: Don't modify generated hardware.nix unless necessary
5. **Version Control**: Commit changes to version control before deploying
6. **Backup**: Keep backups of working configurations
7. **Gradual Changes**: Make incremental changes rather than large modifications