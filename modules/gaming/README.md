# Gaming Module

This module provides comprehensive gaming support for NixOS with proper dependency management.

## Features

- **Steam**: Full Steam client with Proton support
- **Wine/Lutris**: Wine with Staging/GE support and Lutris launcher
- **Performance**: GameMode, MangoHUD, and system optimizations
- **Launchers**: Heroic Games Launcher, RetroArch, and other emulators
- **Dependencies**: Automatic 32-bit library and driver management

## Configuration

### Basic Setup

Enable gaming in your host configuration:

```nix
modules.gaming = {
  enable = true;
  steam.enable = true;
  wine.enable = true;
  performance.enable = true;
};
```

### Advanced Configuration

```nix
modules.gaming = {
  enable = true;
  
  # Steam configuration
  steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = false;
    gamescope.enable = true;
  };
  
  # Wine configuration
  wine = {
    enable = true;
    wine.staging = true;
    wine.ge = true;
    lutris.enable = true;
    bottles.enable = true;
  };
  
  # Performance optimizations
  performance = {
    enable = true;
    gamemode.enable = true;
    mangohud.enable = true;
    cpu.governor = "performance";
  };
  
  # Alternative launchers
  launchers = {
    enable = true;
    heroic.enable = true;
    retroarch.enable = true;
  };
  
  # Dependencies management
  dependencies = {
    enable = true;
    autoGraphics = true;
    nvidiaSupport = true;  # Set based on your GPU
    amdSupport = false;     # Set based on your GPU
  };
};
```

## Requirements

### System Dependencies

- `hardware.opengl.enable = true`
- `hardware.opengl.driSupport32Bit = true`
- `programs.nix-ld.enable = true`

### Graphics Drivers

**NVIDIA:**
```nix
hardware.nvidia = {
  modesetting.enable = true;
  nvidiaSettings = true;
};
```

**AMD:**
```nix
hardware.amdgpu = {
  amdvlk = true;
};
```

## Usage

### Steam

After enabling the module, Steam will be available in your application menu or via:
```bash
steam
```

### Wine/Lutris

```bash
winecfg           # Wine configuration
lutris            # Game launcher
bottles           # Wine prefix manager
```

### Performance Tools

```bash
gamemoderun       # Run games with GameMode
mangohud          # FPS overlay
goverlay          # MangoHUD GUI
```

### Alternative Launchers

```bash
heroic            # Heroic Games Launcher
retroarch         # RetroArch emulator
dolphin-emu       # Dolphin emulator
```

## Troubleshooting

### 32-bit Libraries

If Steam or Wine complain about missing 32-bit libraries:

```bash
nix-shell -p glxinfo --run "glxinfo | grep 'OpenGL renderer'"
```

### GPU Detection

The module auto-detects your GPU, but you can manually specify:

```nix
modules.gaming.dependencies = {
  nvidiaSupport = true;   # For NVIDIA GPUs
  amdSupport = true;      # For AMD GPUs
};
```

### Performance Issues

1. Ensure GameMode is running: `gamemoded -s`
2. Check MangoHUD overlay: `MANGOHUD=1 <game>`
3. Verify GPU drivers: `nvidia-smi` or `radeontop`

## Files Structure

```
modules/gaming/
├── default.nix       # Main module
├── dependencies.nix  # Shared dependencies
├── steam.nix         # Steam configuration
├── wine.nix          # Wine/Lutris configuration
├── performance.nix   # Performance optimizations
├── launchers.nix     # Alternative launchers
└── README.md         # This file
```

## Environment Variables

The module sets several environment variables automatically:

- `STEAM_RUNTIME=1` - Steam runtime
- `WINEESYNC=1` - Wine eventfd synchronization
- `PROTON_NO_ESYNC=0` - Proton event synchronization
- `DXVK_STATE_CACHE_PATH` - DXVK cache location
- `__GLX_VENDOR_LIBRARY_NAME=nvidia` - NVIDIA optimization

## Security

The module sets appropriate capabilities for gaming applications:
- Steam: `cap_sys_nice+ep`
- Wine: `cap_sys_nice+ep`

## Services

- `gamemoded` - GameMode service
- `steam-input` - Steam Input service
- `wine-prefix-update` - Wine prefix updater

## Firewall Ports

### Steam Remote Play (if enabled)
- TCP: 27036-27037
- UDP: 27031-27036

### Steam Dedicated Server (if enabled)
- TCP: 27015-27019
- UDP: 26900-26909