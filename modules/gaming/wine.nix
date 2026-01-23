# Wine and Lutris configuration for Windows gaming
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.gaming.wine;
in
{
  options.modules.gaming.wine = {
    enable = mkEnableOption "Wine and Lutris support";
    
    wine = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Wine for Windows applications";
      };
      
      staging = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Wine Staging for better gaming performance";
      };
      
      ge = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Wine-GE for gaming";
      };
    };
    
    lutris = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Lutris game launcher";
      };
      
      wineRunners = mkOption {
        type = types.bool;
        default = true;
        description = "Install additional Wine runners for Lutris";
      };
    };
    
    bottles = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Bottles for easy Wine prefix management";
      };
    };
    
    winetricks = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Winetricks for installing Windows components";
      };
    };
  };

  config = mkIf cfg.enable {
    # Wine packages
    environment.systemPackages = with pkgs; [
      # Core Wine packages
      wine
      wine64
      wineWow64  # Wine with both 32-bit and 64-bit support
      
      # Wine utilities
      winetricks
      wine-gecko
      wine-mono
      
      # Common Windows libraries that Wine might need
      corefonts
      vistafonts
      
      # Additional compatibility layers
      dxvk
      vkd3d
      
      # Windows multimedia support
      wmf
      gstreamer
      gst-plugins-base
      gst-plugins-good
      gst-plugins-bad
      gst-plugins-ugly
    ] ++ optionals cfg.wine.staging [
      wine-staging
    ] ++ optionals cfg.wine.ge [
      wine-ge
    ] ++ optionals cfg.lutris.enable [
      lutris
    ] ++ optionals cfg.bottles.enable [
      bottles
    ] ++ optionals cfg.lutris.wineRunners [
      # Additional Wine runners for Lutris
      proton-ge-bin
      wine-ge-bin
    ];

    # Wine-specific environment variables will be handled in main gaming module

    # Wine-specific system configurations
    # Note: system.extraCompat is not a standard NixOS option
    # Wine compatibility is handled through packages and configuration

    # Wine-specific services
    systemd.user.services = {
      # Wine prefix updater
      wine-prefix-update = {
        description = "Update Wine prefix";
        wantedBy = [ "graphical-session.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.wine}/bin/wineboot -u";
          RemainAfterExit = true;
        };
      };
    };

    # Lutris-specific configurations
    # Lutris options are configured through the application itself
    # Programs.lutris configuration is not a standard NixOS option

    # Wine-specific security settings
    security = {
      # Allow Wine to set capabilities
      wrappers.wine = mkIf cfg.wine.enable {
        source = "${pkgs.wine}/bin/wine";
        capabilities = "cap_sys_nice+ep";
      };
      
      # Wine network access - user groups configured per-host
    };

    # Wine-specific hardware support
    hardware = {
      # OpenGL support for Wine
      opengl = {
        enable = true;
        driSupport32Bit = true;
        extraPackages = with pkgs; [
          mesa.drivers
          vulkan-loader
        ];
        extraPackages32 = with pkgs.pkgsi686Linux; [
          mesa.drivers
          vulkan-loader
        ];
      };
    };

    # Note: Desktop entries should be configured via home-manager or manually
    # xdg.desktopEntries is not a standard NixOS option

    # Wine-specific file associations
    xdg.mime = {
      defaultApplications = mkIf cfg.wine.enable {
        "application/x-ms-dos-executable" = [ "wine.desktop" ];
        "application/x-wine-extension-cpl" = [ "wine.desktop" ];
        "application/x-wine-extension-inf" = [ "wine.desktop" ];
        "application/x-wine-extension-msp" = [ "wine.desktop" ];
        "application/x-wine-extension-msi" = [ "wine.desktop" ];
      };
    };

    # Wine-specific assertions for dependency validation
    assertions = [
      {
        assertion = config.hardware.opengl.driSupport32Bit;
        message = "Wine requires 32-bit graphics support (hardware.opengl.driSupport32Bit)";
      }
      {
        assertion = config.programs.nix-ld.enable;
        message = "Wine requires nix-ld for binary compatibility";
      }
      {
        assertion = cfg.wine.enable -> config.hardware.opengl.enable;
        message = "Wine requires OpenGL support (hardware.opengl.enable)";
      }
    ];

    # Wine-specific packages for compatibility are already included in main packages
  };
}