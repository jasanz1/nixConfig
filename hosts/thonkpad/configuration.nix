# Host-specific configuration for thonkpad
{ config, lib, pkgs, inputs, ... }:
{
  imports = [
    ./hardware.nix
    ./users.nix
    ../../modules/desktop
    ../../modules/development
    ../../modules/gaming
    ../../modules/system
    ../../modules/networking
    ../../modules/security
    ../../modules/services
    ../../profiles/desktop.nix
    inputs.home-manager.nixosModules.default
  ];

  # Host-specific settings
  networking.hostName = "thonkpad";
  
  # Time zone
  time.timeZone = "America/Los_Angeles";
  
  # Internationalization
  i18n.defaultLocale = "en_US.UTF-8";
  
  # System configuration
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  # Enable nix-ld for gaming binaries
  programs.nix-ld.enable = true;
  
  # Garbage collection
  nix.gc.automatic = true;
  nix.gc.dates = "03:15";
  
  nix.optimise.automatic = true;
  nix.optimise.dates = "03:45";

  # Auto upgrade
  system.autoUpgrade.enable = true;
  
  modules.gaming = {
    enable = lib.mkDefault false;
    steam.enable = lib.mkDefault true;
    performance.enable = lib.mkDefault true;
    launchers.enable = lib.mkDefault false;
    dependencies.autoGraphics = lib.mkDefault true;
  };
  # NVIDIA GPU support  
  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaSettings = true;
    open = true;  # Use open source modules
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
  
  # Video driver configuration
  services.xserver.videoDrivers = [ "nvidia" ];
  
  # Editor
  environment.variables.EDITOR = "nvim";
  programs.neovim.defaultEditor = true;
  
  # Lid switch behavior
  services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore";
  
  # GRUB configuration for bootability
  boot.loader.grub.devices = [ "nodev" ];
  
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  system.stateVersion = "24.05";
}
