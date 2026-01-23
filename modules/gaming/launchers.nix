# Alternative game launchers configuration
# This module provides Heroic, Legendary, and other game launchers
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.gaming.launchers;
in
{
  options.modules.gaming.launchers = {
    enable = mkEnableOption "Alternative game launchers";
    
    heroic = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Heroic Games Launcher (Epic Games & GOG)";
      };
      
      epic = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Epic Games support in Heroic";
      };
      
      gog = mkOption {
        type = types.bool;
        default = true;
        description = "Enable GOG support in Heroic";
      };
    };
    
    legendary = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Legendary CLI for Epic Games";
      };
    };
    
    retroarch = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable RetroArch emulator";
      };
      
      cores = mkOption {
        type = types.listOf types.str;
        default = [
          "snes9x"        # SNES
          "genesis-plus-gx"  # Sega Genesis
          "mupen64plus"   # Nintendo 64
          "pcsx-rearmed"  # PlayStation
          "fbalpha"       # Arcade
          "stella"        # Atari 2600
        ];
        description = "RetroArch cores to install";
      };
    };
    
    emulators = {
      dolphin = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Dolphin emulator (GameCube/Wii)";
      };
      
      pcsx2 = mkOption {
        type = types.bool;
        default = false;
        description = "Enable PCSX2 emulator (PlayStation 2)";
      };
      
      rpcs3 = mkOption {
        type = types.bool;
        default = false;
        description = "Enable RPCS3 emulator (PlayStation 3)";
      };
      
      yuzu = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Yuzu emulator (Nintendo Switch)";
      };
    };
    
    discord = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Discord Rich Presence for games";
      };
    };
  };

  config = mkIf cfg.enable {
    # Alternative launcher packages will be included in main gaming module

    # RetroArch cores
    environment.systemPackages = with pkgs.libretro; 
      (map (core: builtins.getAttr core pkgs.libretro) cfg.retroarch.cores);

    # Heroic Games Launcher configuration
    # Heroic settings are configured through the application itself
    # Programs.heroic configuration is not a standard NixOS option

    # Discord Rich Presence - Discord should be installed via system packages or home-manager
    # programs.discord configuration is handled at user level

    # RetroArch configuration
    # RetroArch settings are configured through the application itself
    # Services.retroarch configuration is not a standard NixOS option

    # Launcher-specific environment variables will be handled in main gaming module

    # Gaming-specific desktop entries
    xdg.desktopEntries = {
      heroic-epic = mkIf (cfg.heroic.enable && cfg.heroic.epic) {
        name = "Heroic (Epic Games)";
        exec = "${pkgs.heroic}/bin/heroic --epic";
        icon = "heroic";
        categories = [ "Game" ];
      };
      
      heroic-gog = mkIf (cfg.heroic.enable && cfg.heroic.gog) {
        name = "Heroic (GOG)";
        exec = "${pkgs.heroic}/bin/heroic --gog";
        icon = "heroic";
        categories = [ "Game" ];
      };
      
      retroarch = mkIf cfg.retroarch.enable {
        name = "RetroArch";
        exec = "${pkgs.retroarch}/bin/retroarch";
        icon = "retroarch";
        categories = [ "Game" "Emulator" ];
      };
      
      dolphin = mkIf cfg.emulators.dolphin {
        name = "Dolphin Emulator";
        exec = "${pkgs.dolphin-emu}/bin/dolphin-emu";
        icon = "dolphin-emu";
        categories = [ "Game" "Emulator" ];
      };
      
      pcsx2 = mkIf cfg.emulators.pcsx2 {
        name = "PCSX2";
        exec = "${pkgs.pcsx2}/bin/pcsx2";
        icon = "pcsx2";
        categories = [ "Game" "Emulator" ];
      };
      
      rpcs3 = mkIf cfg.emulators.rpcs3 {
        name = "RPCS3";
        exec = "${pkgs.rpcs3}/bin/rpcs3";
        icon = "rpcs3";
        categories = [ "Game" "Emulator" ];
      };
      
      yuzu = mkIf cfg.emulators.yuzu {
        name = "Yuzu";
        exec = "${pkgs.yuzu}/bin/yuzu";
        icon = "yuzu";
        categories = [ "Game" "Emulator" ];
      };
    };

    # Game directories will be created on first use

    # Emulator-specific hardware requirements
    hardware = {
      # OpenGL support for emulators
      opengl = mkIf (cfg.retroarch.enable || cfg.emulators.dolphin || cfg.emulators.pcsx2) {
        enable = true;
        driSupport32Bit = true;
      };
      
      # Controller support for emulators
      xpadneo.enable = mkDefault true;
    };

    # Emulator-specific assertions
    assertions = [
      {
        assertion = cfg.retroarch.enable -> config.hardware.opengl.enable;
        message = "RetroArch requires OpenGL support";
      }
      {
        assertion = cfg.emulators.dolphin -> config.hardware.opengl.driSupport32Bit;
        message = "Dolphin requires 32-bit OpenGL support";
      }
      {
        assertion = cfg.heroic.enable -> config.programs.nix-ld.enable;
        message = "Heroic requires nix-ld for binary compatibility";
      }
    ];

    # Additional gaming utilities will be included in main gaming module
  };
}