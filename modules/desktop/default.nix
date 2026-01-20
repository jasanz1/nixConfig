# Desktop modules default configuration
{ config, lib, pkgs, ... }:

{
  imports = [
    ./hyprland.nix
    ./mangowc.nix
  ];

  # Enable Hyprland by default for desktop systems
  modules.desktop.hyprland.enable = lib.mkDefault true;
}