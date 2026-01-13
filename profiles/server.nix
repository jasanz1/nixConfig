# Server Profile Configuration
# This profile provides headless server configuration with essential services
{ config, lib, pkgs, ... }:

{
  imports = [
    ../modules/system
    ../modules/services
    ../modules/security
  ];

  # Server configuration - no desktop environment
  services.xserver.enable = false;
  
  # No audio support in server profile
  sound.enable = false;
  hardware.pulseaudio.enable = false;
  services.pipewire.enable = false;

  # No Bluetooth in server profile
  hardware.bluetooth.enable = false;

  # Server networking configuration
  networking.networkmanager.enable = false;
  networking.wireless.enable = false;
  networking.dhcpcd.enable = true;

  # Enable firewall for server security
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 ]; # SSH by default

  # Server-appropriate system packages
  modules.system.packages = {
    enable = lib.mkDefault true;
    textEditing.enable = lib.mkDefault true;
    utilities.enable = lib.mkDefault true;
    media.enable = lib.mkDefault false;
    networking.enable = lib.mkDefault true;
    fileManagement.enable = lib.mkDefault true;
  };

  # Server-specific packages
  environment.systemPackages = with pkgs; [
    # System administration tools
    wget
    curl
    git
    vim
    htop
    iotop
    tree
    unzip
    rsync
    
    # Networking and monitoring
    iproute2
    iputils
    nettools
    tcpdump
    nmap
    iftop
    
    # System monitoring
    lsof
    strace
    tmux
    screen
    
    # Log analysis
    logrotate
    
    # Backup tools
    borgbackup
  ];

  # Essential server services
  services.openssh = {
    enable = lib.mkDefault true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # System monitoring and logging
  services.journald.extraConfig = ''
    SystemMaxUse=1G
    MaxRetentionSec=1month
  '';

  # Automatic system updates (can be disabled per host)
  system.autoUpgrade = {
    enable = lib.mkDefault false; # Let administrators control this
    allowReboot = lib.mkDefault false;
  };

  # Server-specific security settings
  security.sudo.wheelNeedsPassword = true;
  
  # No fonts needed for headless server
  fonts.packages = [ ];

  # Disable unnecessary services for server
  services.printing.enable = false;
  services.avahi.enable = false;
  services.blueman.enable = false;
  services.geoclue2.enable = false;
  services.power-profiles-daemon.enable = false;

  # Server time synchronization
  services.ntp.enable = true;
}