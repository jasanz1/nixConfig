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
    };
    
    mangohud = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable MangoHUD for FPS monitoring";
      };
    };
  };

  config = mkIf cfg.enable {
    # GameMode for performance optimization
    programs.gamemode = mkIf cfg.gamemode.enable {
      enable = true;
    };

    # MangoHUD for FPS monitoring
    environment.systemPackages = with pkgs; [
      mangohud
    ];

    # CPU performance optimizations
    powerManagement.cpuFreqGovernor = mkDefault "performance";

    # Kernel parameters for gaming performance
    boot.kernelParams = [
      "transparent_hugepage=always"
      "hugepagesz=2M"
      "hugepages=1024"
    ] ++ optionals config.modules.gaming.dependencies.nvidiaSupport [
      "nvidia-drm.modeset=1"
      "nvidia-drm.fbdev=1"
    ];

    # Gaming-specific environment variables
    environment.sessionVariables = {
      # General performance optimizations
      SDL_AUDIODRIVER = "pipewire";
      
      # DXVK optimizations
      DXVK_STATE_CACHE_PATH = "$HOME/.local/share/dxvk";
      DXVK_HUD = "fps";
    } // optionalAttrs config.modules.gaming.dependencies.nvidiaSupport {
      # NVIDIA-specific performance variables
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      __GL_SHADER_DISK_CACHE = "1";
      __GL_SHADER_DISK_CACHE_PATH = "$HOME/.cache/nvidia";
    };
  };
}