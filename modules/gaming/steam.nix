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
    ] ++ optionals cfg.proton.geProton [
      # GE-Proton will be managed through protonup-qt
    ];

    # Steam-specific services
    systemd.user.services = {
      # Steam input service for controller support
      steam-input = {
        description = "Steam Input Service";
        wantedBy = [ "graphical-session.target" ];
        serviceConfig = {
          ExecStart = "${pkgs.steam}/bin/steam -silent -no-cef-sandbox";
          Restart = "on-failure";
        };
      };
    };

    # Steam-specific environment variables will be handled in main gaming module

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
      xpadneo.enable = mkDefault true;
    };

    # Steam-specific security settings
    security = {
      # Allow Steam to set capabilities for performance
      wrappers.steam = {
        source = "${pkgs.steam}/bin/steam";
        capabilities = "cap_sys_nice+ep";
      };
      
      # Steam input - user groups configured per-host
    };

    # Steam-specific system configurations
    systemd = {
      # Steam input service
      services.steam-input = {
        description = "Steam Input Service";
        wantedBy = [ "graphical-session.target" ];
        serviceConfig = {
          ExecStart = "${pkgs.steam}/bin/steam -silent -no-cef-sandbox";
          Restart = "on-failure";
          User = "%i";
        };
      };
    };

    # Steam-specific desktop entries
    xdg.desktopEntries = {
      steam-big-picture = {
        name = "Steam (Big Picture Mode)";
        exec = "${pkgs.steam}/bin/steam -bigpicture";
        icon = "steam";
        categories = [ "Game" ];
      };
      
      steam-streaming = {
        name = "Steam Streaming";
        exec = "${pkgs.steam}/bin/steam -streaming";
        icon = "steam";
        categories = [ "Game" ];
      };
    } // optionalAttrs cfg.gamescope.enable {
      steam-gamescope = {
        name = "Steam (Gamescope)";
        exec = "${pkgs.gamescope}/bin/gamescope -w 1920 -h 1080 -f -- ${pkgs.steam}/bin/steam";
        icon = "steam";
        categories = [ "Game" ];
      };
    };

    # Steam-specific assertions for dependency validation
    assertions = [
      {
        assertion = config.hardware.opengl.driSupport32Bit;
        message = "Steam requires 32-bit graphics support (hardware.opengl.driSupport32Bit)";
      }
      {
        assertion = config.programs.nix-ld.enable;
        message = "Steam requires nix-ld for binary compatibility";
      }
      {
        assertion = config.hardware.steam-hardware.enable;
        message = "Steam requires hardware support for controllers";
      }
    ];
  };
}