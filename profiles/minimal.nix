# Minimal Profile Configuration
# This profile provides only essential system components
{ config, lib, pkgs, ... }:

{
  imports = [
    ../modules/system
  ];

  # Minimal system configuration - no desktop environment
  services.xserver.enable = false;
  
  # No audio support in minimal profile
  sound.enable = false;
  hardware.pulseaudio.enable = false;
  services.pipewire.enable = false;

  # No Bluetooth in minimal profile
  hardware.bluetooth.enable = false;

  # Basic networking only
  networking.networkmanager.enable = false;
  networking.wireless.enable = false;
  networking.dhcpcd.enable = true;

  # Minimal system packages only
  modules.system.packages = {
    enable = lib.mkDefault true;
    textEditing.enable = lib.mkDefault true;
    utilities.enable = lib.mkDefault true;
    media.enable = lib.mkDefault false;
    networking.enable = lib.mkDefault false;
    fileManagement.enable = lib.mkDefault false;
  };

  # Essential system packages only
  environment.systemPackages = with pkgs; [
    # Basic system utilities
    wget
    curl
    git
    vim
    htop
    tree
    unzip
    
    # Basic networking tools
    iproute2
    iputils
    nettools
  ];

  # Minimal services
  services.openssh.enable = lib.mkDefault false;
  services.printing.enable = false;
  services.avahi.enable = false;

  # No development tools by default
  # Users can enable them explicitly if needed

  # Basic fonts only
  fonts.packages = with pkgs; [
    dejavu_fonts
  ];
}