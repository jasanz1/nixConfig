# Steam gaming platform configuration
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.gaming.steam;
in
{
  options.modules.gaming.steam = {
    enable = mkEnableOption "Steam gaming platform";
    
    remotePlay = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Steam Remote Play";
      };
      
      openFirewall = mkOption {
        type = types.bool;
        default = true;
        description = "Open firewall ports for Steam Remote Play";
      };
    };
    
    dedicatedServer = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Steam Dedicated Server support";
      };
      
      openFirewall = mkOption {
        type = types.bool;
        default = false;
        description = "Open firewall ports for Steam Dedicated Server";
      };
    };
    
    gamescope = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Gamescope for Steam games";
      };
    };
    
    proton = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Proton support for Windows games";
      };
      
      geProton = mkOption {
        type = types.bool;
        default = true;
        description = "Enable GE-Proton for better compatibility";
      };
    };
  };

  config = mkIf cfg.enable {
    # Enable Steam with proper configuration
    programs.steam = {
      enable = true;
      
      # Remote Play configuration
      remotePlay.openFirewall = cfg.remotePlay.openFirewall;
      
      # Dedicated Server configuration
      dedicatedServer.openFirewall = cfg.dedicatedServer.openFirewall;
      
      # Gamescope session support
      gamescopeSession.enable = cfg.gamescope.enable;
    };

    # Steam packages and utilities
    environment.systemPackages = with pkgs; [
      steam          # Main Steam client
      
      # Steam utilities
      steam-run      # Run non-NixOS binaries with Steam runtime
      steam-tui      # Terminal Steam interface
      
      # Proton management
      protonup-qt    # GUI for managing Proton versions
    ];

    # Steam-specific environment variables
    environment.sessionVariables = {
      # Steam runtime optimizations
      STEAM_RUNTIME = "1";
      
      # Proton optimizations
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = mkIf cfg.proton.enable 
        "$HOME/.steam/root/compatibilitytools.d";
      
      # Steam input
      STEAM_INPUT_METHOD = "gamepadui";
      
      # Steam flatpak compatibility
      STEAM_USE_RUNTIME_AUDIO = "1";
    };

    # Steam-specific firewall rules
    networking.firewall = mkMerge [
      (mkIf cfg.remotePlay.openFirewall {
        # Steam Remote Play ports
        allowedTCPPorts = [ 27036 27037 ];
        allowedUDPPorts = [ 27031 27032 27033 27034 27035 27036 ];
      })
      (mkIf cfg.dedicatedServer.openFirewall {
        # Steam Dedicated Server ports
        allowedTCPPorts = [ 27015 27016 27017 27018 27019 ];
        allowedUDPPorts = [ 26900 26901 26902 26903 26904 26905 26906 26907 26908 26909 ];
      })
    ];

    # Steam-specific hardware support
    hardware = {
      # Steam controller and other gaming devices
      steam-hardware.enable = true;
      
      # Additional controller support
      xpadneo.enable = true;
    };

    # Steam-specific security settings
    security.wrappers = {
      steam = {
        source = "${pkgs.steam}/bin/steam";
        capabilities = "cap_sys_nice+ep";
        owner = "root";
        group = "users";
      };
    };

    # Steam-specific assertions for dependency validation
  };
}
