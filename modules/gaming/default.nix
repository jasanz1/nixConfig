# Gaming module main configuration
# This module provides comprehensive gaming support with proper dependency management
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.gaming;
in
{
  options.modules.gaming = {
    enable = mkEnableOption "Gaming support";
    
    # Core gaming components
    steam = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Steam gaming platform";
      };
    };
    
    wine = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Wine/Lutris support";
      };
    };
    
    performance = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable gaming performance optimizations";
      };
    };
    
    launchers = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable alternative game launchers";
      };
    };
    
    # Dependencies management
    dependencies = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable gaming dependencies (required for most gaming features)";
      };
      
      autoGraphics = mkOption {
        type = types.bool;
        default = true;
        description = "Automatically configure graphics drivers";
      };
      
      nvidiaSupport = mkOption {
        type = types.bool;
        default = config.hardware.nvidia.modesetting.enable or false;
        description = "Enable NVIDIA-specific optimizations";
      };
      
      amdSupport = mkOption {
        type = types.bool;
        default = config.hardware.amdgpu.amdvlk or false;
        description = "Enable AMD-specific optimizations";
      };
    };
    
    # Advanced options
    vr = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable VR gaming support";
      };
    };
    
    streaming = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable game streaming support";
      };
    };
  };

  # Import all gaming submodules
  imports = [
    ./dependencies.nix
    ./steam.nix
    ./wine.nix
    ./performance.nix
    ./launchers.nix
  ];

  config = mkIf cfg.enable {

    # Enable dependencies by default
    modules.gaming.dependencies.enable = mkDefault true;

    # Core gaming assertions
    assertions = [
      # Basic system requirements
      {
        assertion = config.hardware.opengl.enable;
        message = "Gaming module requires OpenGL support (hardware.opengl.enable)";
      }
      {
        assertion = config.hardware.opengl.driSupport32Bit;
        message = "Gaming module requires 32-bit graphics support (hardware.opengl.driSupport32Bit)";
      }
      {
        assertion = config.programs.nix-ld.enable;
        message = "Gaming module requires nix-ld for binary compatibility (programs.nix-ld.enable)";
      }
      
      # Steam-specific assertions
      {
        assertion = cfg.steam.enable -> cfg.dependencies.enable;
        message = "Steam requires gaming dependencies to be enabled";
      }
      
      # Wine-specific assertions
      {
        assertion = cfg.wine.enable -> cfg.dependencies.enable;
        message = "Wine requires gaming dependencies to be enabled";
      }
      
      # Performance-specific assertions
      {
        assertion = cfg.performance.enable -> cfg.dependencies.enable;
        message = "Performance optimizations require gaming dependencies";
      }
      
      # Graphics driver assertions
      {
        assertion = cfg.dependencies.nvidiaSupport -> config.hardware.nvidia.modesetting.enable;
        message = "NVIDIA gaming support requires NVIDIA driver with modesetting";
      }
      {
        assertion = cfg.dependencies.amdSupport -> config.hardware.amdgpu.amdvlk;
        message = "AMD gaming support requires AMDVLK";
      }
    ];

    # Gaming-specific system packages
    environment.systemPackages = with pkgs; [
      # Core gaming utilities
      glxinfo              # OpenGL information
      vulkan-tools        # Vulkan utilities
      dxvk                # DirectX to Vulkan translation
      vkd3d               # Direct3D 12 to Vulkan
      
      # Gaming tools
      protontricks        # Proton utility
      winetricks          # Wine component installer
      
      # Performance monitoring
      nvtop               # GPU monitoring
      btop                # System monitor
      
      # MangoHUD and performance tools
      mangohud
    ] ++ optionals cfg.launchers.goverlay.enable [
      goverlay
    ] ++ optionals cfg.wine.enable [
      # Core Wine packages
      wine
      wine64
      wineWow64
      wine-gecko
      wine-mono
      
      # Wine compatibility layers
      wine-staging
      wine-ge
    ] ++ optionals cfg.wine.lutris.enable [
      lutris
    ] ++ optionals cfg.wine.bottles.enable [
      bottles
    ] ++ optionals cfg.wine.lutris.wineRunners [
      proton-ge-bin
      wine-ge-bin
    ] ++ optionals cfg.launchers.heroic.enable [
      heroic
    ] ++ optionals cfg.launchers.legendary.enable [
      legendary
    ] ++ optionals cfg.launchers.retroarch.enable [
      retroarch
    ] ++ optionals cfg.launchers.emulators.dolphin [
      dolphin-emu
    ] ++ optionals cfg.launchers.emulators.pcsx2 [
      pcsx2
    ] ++ optionals cfg.launchers.emulators.rpcs3 [
      rpcs3
    ] ++ optionals cfg.launchers.emulators.yuzu [
      yuzu
    ] ++ optionals cfg.vr.enable [
      # VR support packages
      monado-vulkan-layer
      openxr-loader
    ] ++ optionals cfg.streaming.enable [
      # Game streaming packages
      obs-studio          # Open Broadcaster Software
      sunshine            # Game streaming server
    ];

    # Gaming-specific environment variables
    environment.sessionVariables = {
      # Steam optimizations
      STEAM_RUNTIME = "1";
      STEAM_INPUT_METHOD = "gamepadui";
      STEAM_USE_RUNTIME_AUDIO = "1";
      
      # Proton optimizations
      PROTON_USE_WINED3D = "0";
      PROTON_NO_ESYNC = "0";
      PROTON_NO_FSYNC = "0";
      
      # DXVK optimizations
      DXVK_STATE_CACHE_PATH = "$HOME/.local/share/dxvk";
      DXVK_HUD = "fps";
      
      # Wine optimizations
      WINEDEBUG = "-all";
      WINEDLLOVERRIDES = "mshtml=;d3d10core=n;dxgi=n";
      WINEPREFIX = "$HOME/.wine";
      WINEESYNC = "1";
      WINEFSYNC = "1";
      PULSE_LATENCY_MSEC = "60";
      
      # Heroic launcher settings
      HEROIC_INSTALL_PATH = mkIf cfg.launchers.heroic.enable "$HOME/Games";
      
      # RetroArch settings
      RETROARCH_CONFIG_DIR = mkIf cfg.launchers.retroarch.enable "$HOME/.config/retroarch";
      
      # MangoHUD configuration
      MANGOHUD_CONFIG = mkIf cfg.performance.mangohud.enable (lib.concatStringsSep "," (
        lib.mapAttrsToList (key: value: 
          if value == true then key
          else if value == false then "no_${key}"
          else "${key}=${toString value}"
        ) ({
          fps = true;
          frametime = true;
          cpu_temp = true;
          gpu_temp = true;
          vram = true;
          position = "top-left";
          background_alpha = "0.4";
          font_size = "24";
        } // cfg.performance.mangohud.settings)
      ));
      
      # Discord settings
      DISCORD_RPC_CLIENT_ID = mkIf cfg.launchers.discord.enable "0";
    } // optionalAttrs cfg.dependencies.nvidiaSupport {
      # NVIDIA-specific variables
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      __NV_PRIME_RENDER_OFFLOAD = "1";
      __VK_LAYER_NV_optimus = "NVIDIA_only";
      __GL_SHADER_DISK_CACHE = "1";
      __GL_SHADER_DISK_CACHE_PATH = "$HOME/.cache/nvidia";
      __GL_THREADED_OPTIMIZATIONS = "1";
      __GL_YIELD = "USLEEP";
    } // optionalAttrs cfg.dependencies.amdSupport {
      # AMD-specific variables
      VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json";
    };

    # Gaming-specific kernel parameters
    boot.kernelParams = [
      # General gaming optimizations
      "transparent_hugepage=always"
      "hugepagesz=2M"
      "hugepages=1024"
    ] ++ optionals cfg.dependencies.nvidiaSupport [
      # NVIDIA-specific parameters
      "nvidia-drm.modeset=1"
      "nvidia-drm.fbdev=1"
    ];

    # Gaming-specific services
    services = {
      # udev rules for gaming devices
      udev.packages = with pkgs; [
        steam-udev-rules
      ];
    };

    # Gaming-specific security settings
    security.wrappers = mkMerge [
      (mkIf cfg.steam.enable {
        steam = {
          source = "${pkgs.steam}/bin/steam";
          capabilities = "cap_sys_nice+ep";
        };
      })
      (mkIf cfg.wine.enable {
        wine = {
          source = "${pkgs.wine}/bin/wine";
          capabilities = "cap_sys_nice+ep";
        };
      })
    ];

    # Gaming-specific hardware support
    hardware = mkMerge [
      (mkIf cfg.dependencies.enable {
        # Core gaming hardware support
        steam-hardware.enable = true;
        
        # Controller support
        xpadneo.enable = mkDefault true;
      })
      (mkIf cfg.dependencies.nvidiaSupport {
        # NVIDIA gaming optimizations
        nvidia = {
          modesetting.enable = true;
          nvidiaSettings = true;
          package = config.boot.kernelPackages.nvidiaPackages.stable;
          powerManagement.enable = mkDefault true;
        };
      })
      (mkIf cfg.dependencies.amdSupport {
        # AMD gaming optimizations
        amdgpu = {
          amdvlk = mkDefault true;
          opencl.enable = mkDefault true;
        };
      })
    ];

    # Gaming-specific file system optimizations
    fileSystems = mkIf cfg.performance.enable {
      "/tmp".options = [ "noatime" "nodiratime" ];
    };

    # Gaming-specific memory management
    vm.swappiness = mkIf cfg.performance.enable (mkDefault 10);

    # Gaming-specific desktop entries
    xdg.desktopEntries = {
      gaming-info = {
        name = "Gaming Information";
        exec = "${pkgs.bash}/bin/bash -c 'echo \"Gaming module is active\"'";
        icon = "applications-games";
        categories = [ "System" ];
      };
    };

    # Note: User groups for gaming (input, audio, video) should be configured per-host
    # Example: users.users.<username>.extraGroups = [ "input" "audio" "video" ];

    # Gaming-specific system state
    system.stateVersion = config.system.stateVersion;
  };
}