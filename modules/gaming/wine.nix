# Wine/Lutris configuration module
# This module provides Wine, Lutris, and Bottles support
{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.modules.gaming.wine;
in
{
  options.modules.gaming.wine = {
    enable = mkEnableOption "Wine support";

    staging = mkEnableOption "Wine Staging patches" // {
      default = true;
    };

    ge = mkEnableOption "Wine GE (Glorious Eggroll) patches" // {
      default = true;
    };

    lutris = {
      enable = mkEnableOption "Lutris launcher support";
      wineRunners = mkEnableOption "Install Wine/Proton GE runners for Lutris" // {
        default = true;
      };
    };

    bottles = {
      enable = mkEnableOption "Bottles support";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      wine
      winetricks
    ] ++ optionals cfg.lutris.enable [
      lutris
    ] ++ optionals cfg.bottles.enable [
      bottles
    ] ++ optionals cfg.lutris.wineRunners [
      inputs.nix-gaming.packages.${pkgs.stdenv.hostPlatform.system}.wine-ge-bin
      inputs.nix-gaming.packages.${pkgs.stdenv.hostPlatform.system}.proton-ge-bin
    ];

    environment.sessionVariables = {
      WINEESYNC = "1";
      WINEFSYNC = "1";
      WINEDEBUG = "-all";
      WINEDLLOVERRIDES = "mshtml=;d3d10core=n;dxgi=n";
      WINEPREFIX = "$HOME/.wine";
    } // optionalAttrs cfg.lutris.enable {
      LUTRIS_SITE_URL = "https://lutris.net";
    } // optionalAttrs cfg.bottles.enable {
      BOTTLES_SITE_URL = "https://usebottles.com";
    };
  };
}
