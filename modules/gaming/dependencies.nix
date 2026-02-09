# Shared gaming dependencies
# This module handles core dependencies required for gaming on NixOS
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.gaming.dependencies;
in
{
  options.modules.gaming.dependencies = {
    enable = mkEnableOption "Gaming dependencies";
    
    autoGraphics = mkOption {
      type = types.bool;
      default = true;
      description = "Automatically configure graphics drivers based on available hardware";
    };
    
    nvidiaSupport = mkOption {
      type = types.bool;
      default = config.hardware.nvidia.modesetting.enable or false;
      description = "Enable NVIDIA-specific gaming optimizations";
    };
    
    amdSupport = mkOption {
      type = types.bool;
      default = config.hardware.amdgpu.amdvlk or false;
      description = "Enable AMD-specific gaming optimizations";
    };
  };

  config = mkIf cfg.enable {
    # CRITICAL: 32-bit graphics support for Steam and games
    hardware.graphics.enable32Bit = true;
    
    # OpenGL support with gaming-specific packages
    hardware.graphics.enable = true;
    hardware.graphics.extraPackages = with pkgs; [
      mesa
      # Vulkan support
      vulkan-loader
      vulkan-validation-layers
    ] ++ optionals cfg.nvidiaSupport [
      # NVIDIA Vulkan support
      nvidia-vaapi-driver
    ] ++ optionals cfg.amdSupport [
      # AMD Vulkan support
      amdvlk
    ];

    # nix-ld for running non-NixOS binaries (games, launchers)
    programs.nix-ld.enable = true;
    programs.nix-ld.libraries = with pkgs; [
      # Common libraries that games might need
      stdenv.cc.cc
      zlib
      glibc
      curl
      openssl
      sqlite
      dbus
      expat
      fontconfig
      freetype
      libxkbcommon
      libxkbfile
      libdrm
      wayland
      libX11
      libXcursor
      libXext
      libXi
      libXrandr
      libXrender
      libXtst
      libXfixes
      libXcomposite
      libXdamage
      libXScrnSaver
      libXinerama
    ];

    # Gaming kernel modules
    boot.kernelModules = [
      "uinput"        # For game controllers (Xbox, etc.)
      "joydev"        # For joystick devices
      "hid_logitech"  # Logitech gaming devices
      "hid_logitech_dj"  # Logitech wireless receivers
    ] ++ optionals cfg.nvidiaSupport [
      "nvidia"        # NVIDIA driver
      "nvidia_drm"    # NVIDIA DRM for direct rendering (if available)
      "nvidia_uvm"    # NVIDIA Unified Memory (if available)
    ];

    # NVIDIA-specific gaming optimizations
    hardware.nvidia = mkIf cfg.nvidiaSupport {
      modesetting.enable = true;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      open = mkDefault false;  # Use open source modules to avoid assertion
      
      # Power management for gaming laptops
      powerManagement.enable = mkDefault true;
      powerManagement.finegrained = mkDefault false;
    };

    # AMD-specific gaming optimizations
    hardware.amdgpu = mkIf cfg.amdSupport {
      amdvlk = mkDefault true;
      opencl.enable = mkDefault true;
    };

    # Controller support
    hardware.xpadneo.enable = mkDefault true;  # Xbox controller improvements
    services.joycond.enable = mkDefault true;  # Switch controller support
    
    # Note: User groups for gaming (input, audio, video) should be configured per-host

    # Gaming-specific system packages
    environment.systemPackages = with pkgs; [
      # Gaming utilities
      glxinfo          # OpenGL information
      vulkan-tools     # Vulkan utilities
      dxvk             # DirectX to Vulkan translation
      mangohud         # FPS overlay
      goverlay         # MangoHUD GUI
      gamemode         # Performance optimization
      protontricks     # Proton utility
      winetricks       # Wine component installer
      
      # Controller utilities
      evtest           # Input device testing
      joystick         # Joystick utilities
      
      # Performance monitoring
      nvtop            # GPU monitoring (NVIDIA/AMD)
      btop             # System monitor
    ];

    # GameMode service for performance optimization
    programs.gamemode.enable = true;

    # Gaming-specific environment variables
    environment.sessionVariables = {
      # Steam runtime optimizations
      STEAM_RUNTIME = "1";
      
      # Proton optimizations
      PROTON_USE_WINED3D = "0";
      PROTON_NO_ESYNC = "0";
      PROTON_NO_FSYNC = "0";
      
      # DXVK optimizations
      DXVK_STATE_CACHE_PATH = "$HOME/.local/share/dxvk";
      DXVK_HUD = "fps";
    } // optionalAttrs cfg.nvidiaSupport {
      # NVIDIA-specific variables
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      __NV_PRIME_RENDER_OFFLOAD = "1";
      __VK_LAYER_NV_optimus = "NVIDIA_only";
    };

    # Gaming-specific services
    services = {
      # udev rules for gaming devices
      udev.packages = with pkgs; [
        steam-udev-rules  # Steam controller and other gaming devices
      ];
    };

    # Security for gaming
    security = {
      # Allow Steam to set capabilities for performance
      wrappers = {
        steam = {
          source = "${pkgs.steam}/bin/steam";
          capabilities = "cap_sys_nice+ep";
        };
      };
    };
  };
}
