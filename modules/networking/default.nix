# Networking modules default configuration
{ config, lib, pkgs, ... }:

{
  # Wireless networking configuration
  networking.wireless = {
    enable = true;
    userControlled.enable = true;
    networks."Heights Alliance 1A".psk = "Allmight=Dadmight";
  };
}