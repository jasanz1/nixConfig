# Desktop Modules

This directory contains modules for desktop environment configuration and window managers.

## Available Modules

### Hyprland Window Manager (`hyprland.nix`)

A modern Wayland compositor with advanced features.

#### Options

```nix
modules.desktop.hyprland = {
  enable = true;  # Enable Hyprland window manager
  
  # Additional configuration options available in the module
  # See hyprland.nix for full option set
};
```

#### Features

- **Wayland Compositor**: Modern display server protocol
- **Tiling Window Manager**: Automatic window arrangement
- **Animations**: Smooth window transitions and effects
- **Multi-Monitor Support**: Advanced monitor configuration
- **Customizable**: Extensive configuration options

#### Dependencies

- Wayland display server
- Graphics drivers with Wayland support
- Audio system (PipeWire recommended)

#### Usage

Enable in your host configuration or profile:

```nix
{
  imports = [ ./modules/desktop ];
  
  modules.desktop.hyprland.enable = true;
}
```

#### Configuration

The module provides sensible defaults but can be customized:

```nix
# Custom Hyprland configuration
modules.desktop.hyprland = {
  enable = true;
  # Additional customization options available
  # Check the module file for specific options
};
```

## Default Configuration

The `default.nix` file in this directory:
- Imports all desktop modules
- Sets reasonable defaults for desktop systems
- Enables Hyprland by default when desktop modules are imported

## Adding New Desktop Modules

To add a new desktop module:

1. Create a new `.nix` file in this directory
2. Follow the existing module structure with options and config sections
3. Import the new module in `default.nix`
4. Update this README with documentation

## Troubleshooting

### Hyprland Issues

**Display Problems**
- Ensure graphics drivers support Wayland
- Check monitor configuration in Hyprland config
- Verify display server is running

**Input Issues**
- Check keyboard/mouse configuration
- Verify input devices are detected
- Review Hyprland input settings

**Performance Issues**
- Check graphics driver installation
- Verify hardware acceleration is working
- Review compositor settings

### Getting Help

- Hyprland documentation: https://hyprland.org/
- NixOS Hyprland wiki: https://nixos.wiki/wiki/Hyprland
- Check system logs: `journalctl -u display-manager`