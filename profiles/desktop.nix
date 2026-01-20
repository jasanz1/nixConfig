# Desktop Profile Configuration
# This profile combines desktop modules for a complete workstation setup
{ config, lib, pkgs, ... }:

{
  imports = [
    ../modules/desktop
    ../modules/development
    ../modules/system
    ../modules/networking
    ../modules/services
  ];

  # Desktop-specific system configuration
  services.xserver.enable = true;
  services.displayManager.gdm = {
      enable = true;
      wayland = true;
    };

  # Audio support for desktop
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Bluetooth support for desktop peripherals
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Desktop-specific services
  services.printing.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # Enable desktop modules with appropriate defaults
  modules.desktop.hyprland.enable = lib.mkDefault true;
  modules.desktop.mangowc.enable = lib.mkDefault true;
  
  modules.development = {
    languages.enable = lib.mkDefault true;
    tools.enable = lib.mkDefault true;
  };

  modules.system.packages = {
    enable = lib.mkDefault true;
    textEditing.enable = lib.mkDefault true;
    utilities.enable = lib.mkDefault true;
    media.enable = lib.mkDefault true;
    networking.enable = lib.mkDefault true;
    fileManagement.enable = lib.mkDefault true;
  };

  # Desktop environment packages
  environment.systemPackages = with pkgs; [
    # Desktop applications
    firefox
    thunderbird
    libreoffice
    gimp
    vlc
    
    # System utilities for desktop
    nautilus
    file-roller
    eog
    evince
    
    # Desktop development tools
    vscode
    
    # Communication
    discord
    slack
  ];

  # Enable common desktop fonts
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
  ];

  # Enable location services for desktop
  services.geoclue2.enable = true;

  # Desktop power management
  services.power-profiles-daemon.enable = true;
}
