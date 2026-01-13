# Networking modules default configuration
{ config, lib, pkgs, ... }:

{
  # Wireless networking configuration
  networking = {
    networkmanager.wifi.backend = "iwd";
    wireless= {
      iwd = { 
        enable = true;
        settings.Settings.autoConnect = true;
      };
    userControlled.enable = true;
    };
  };
}
