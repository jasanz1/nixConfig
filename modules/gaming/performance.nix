# Gaming performance optimizations
# This module provides GameMode, MangoHUD, and other performance tools
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.gaming.performance;
in
{
  options.modules.gaming.performance = {
    enable = mkEnableOption "Gaming performance optimizations";
    
    gamemode = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable GameMode for performance optimization";
      };
      
      settings = mkOption {
        type = types.attrs;
        default = {};
        description = "GameMode configuration settings";
        example = {
          defaultgov = "performance";
          desiredgov = "performance";
          ioprio = "high";
          renice = "-5";
        };
      };
    };
    
    mangohud = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable MangoHUD for FPS monitoring";
      };
      
      settings = mkOption {
        type = types.attrs;
        default = {};
        description = "MangoHUD configuration settings";
        example = {
          fps = true;
          frametime = true;
          cpu_temp = true;
          gpu_temp = true;
          vram = true;
          position = "top-left";
        };
      };
    };
    
    goverlay = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable GOverlay for MangoHUD GUI";
      };
    };
    
    cpu = {
      governor = mkOption {
        type = types.enum [ "powersave" "ondemand" "performance" ];
        default = "performance";
        description = "CPU governor for gaming";
      };
      
      cores = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Number of CPU cores to use for gaming (null = all)";
      };
    };
    
    memory = {
      swappiness = mkOption {
        type = types.int;
        default = 10;
        description = "VM swappiness value (lower = less swapping)";
      };
    };
  };

  config = mkIf cfg.enable {
    # GameMode for performance optimization
    programs.gamemode = mkIf cfg.gamemode.enable {
      enable = true;
      settings = cfg.gamemode.settings // {
        # Default GameMode settings
        defaultgov = mkDefault "performance";
        desiredgov = mkDefault "performance";
        ioprio = mkDefault "high";
        renice = mkDefault "-5";
        
        # GPU optimizations
        apply_gpu_optimisations = mkDefault "1";
        gpu_device = mkDefault "0";
        
        # CPU optimizations
        inhibit_screensaver = mkDefault "1";
        
        # Custom settings
      } // cfg.gamemode.settings;
    };

    # MangoHUD for FPS monitoring
    environment.systemPackages = with pkgs; [
      mangohud
    ] ++ optionals cfg.goverlay.enable [
      goverlay
    ];

    # CPU performance optimizations
    powerManagement.cpuFreqGovernor = mkIf (cfg.cpu.governor != null) cfg.cpu.governor;

    # Memory performance optimizations
    vm.swappiness = mkDefault cfg.memory.swappiness;

    # Kernel parameters for gaming performance
    boot.kernelParams = [
      # Improve gaming performance
      "transparent_hugepage=always"
      "hugepagesz=2M"
      "hugepages=1024"
      
      # NVIDIA-specific optimizations
    ] ++ optionals config.modules.gaming.dependencies.nvidiaSupport [
      "nvidia-drm.modeset=1"
      "nvidia-drm.fbdev=1"
      "nvidia.NVreg_RegistryDwords=PowerMizerEnable=0x1"
    ];

    # Performance monitoring packages will be included in main gaming module

    # Gaming-specific system services
    systemd = {
      # Performance monitoring service
      services.gaming-performance = {
        description = "Gaming Performance Monitor";
        wantedBy = [ "graphical-session.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.bash}/bin/bash -c 'echo \"Gaming performance optimizations active\"'";
          RemainAfterExit = true;
        };
      };
    };

    # Gaming-specific environment variables
    environment.sessionVariables = {
      # General performance optimizations
      SDL_AUDIODRIVER = "pipewire";
      ALSA_PCM_CARD = "PCH";
      
      # Proton optimizations
      PROTON_USE_WINED3D = "0";
      PROTON_NO_ESYNC = "0";
      PROTON_NO_FSYNC = "0";
      
      # DXVK optimizations
      DXVK_STATE_CACHE_PATH = "$HOME/.local/share/dxvk";
      DXVK_HUD = "fps";
      
      # Vulkan optimizations
      VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.json:/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json";
    } // optionalAttrs config.modules.gaming.dependencies.nvidiaSupport {
      # NVIDIA-specific performance variables
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      __GL_SHADER_DISK_CACHE = "1";
      __GL_SHADER_DISK_CACHE_PATH = "$HOME/.cache/nvidia";
      __GL_THREADED_OPTIMIZATIONS = "1";
      __GL_YIELD = "USLEEP";
    };

    # Gaming-specific desktop entries
    xdg.desktopEntries = {
      mangohud-config = {
        name = "MangoHUD Configuration";
        exec = "${pkgs.mangohud}/bin/mangohud --config";
        icon = "mangohud";
        categories = [ "System" "Settings" ];
      };
    } // optionalAttrs cfg.goverlay.enable {
      goverlay = {
        name = "GOverlay";
        exec = "${pkgs.goverlay}/bin/goverlay";
        icon = "goverlay";
        categories = [ "Game" "System" ];
      };
    };

    # Gaming-specific file system optimizations
    fileSystems = mkIf (cfg.memory.swappiness < 20) {
      "/tmp".options = [ "noatime" "nodiratime" ];
    };

    # Performance assertions
    assertions = [
      {
        assertion = cfg.gamemode.enable -> config.programs.gamemode.enable;
        message = "GameMode must be properly enabled";
      }
      {
        assertion = cfg.cpu.governor == "performance" -> config.powerManagement.cpuFreqGovernor == "performance";
        message = "CPU governor must be set to performance for gaming";
      }
    ];
  };
}