# Host-specific configuration for meridian
{ config, lib, pkgs, inputs, ... }:
{
  imports = [
    ./hardware.nix
    ./users.nix
    ../../modules/desktop
    ../../modules/development
    ../../modules/system
    ../../modules/networking
    ../../modules/security
    ../../modules/services
    ../../profiles/desktop.nix
    inputs.home-manager.nixosModules.default
  ];

  # Host-specific settings
  networking.hostName = "meridian";
  
  # Time zone
  time.timeZone = "America/Los_Angeles";
  
  # Internationalization
  i18n.defaultLocale = "en_US.UTF-8";
  
  # System configuration
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  # Garbage collection
  nix.gc.automatic = true;
  nix.gc.dates = "03:15";
  
  # Auto upgrade
  system.autoUpgrade.enable = true;
  
  # Boot loader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  # Editor
  environment.variables.EDITOR = "nvim";
  programs.neovim.defaultEditor = true;
  
  # Lid switch behavior
  services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore";
  
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  system.stateVersion = "24.05";
}
