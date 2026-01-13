# System modules default configuration
{ config, lib, pkgs, ... }:

{
  imports = [
    ./packages.nix
  ];

  # Enable system packages by default
  modules.system.packages = {
    enable = lib.mkDefault true;
    textEditing.enable = lib.mkDefault true;
    utilities.enable = lib.mkDefault true;
    media.enable = lib.mkDefault true;
    networking.enable = lib.mkDefault true;
    fileManagement.enable = lib.mkDefault true;
  };
}