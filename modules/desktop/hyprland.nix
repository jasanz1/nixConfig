# Hyprland window manager module
{ config, lib, pkgs, ... }:

with lib;

{
  options.modules.desktop.hyprland = {
    enable = mkEnableOption "Hyprland window manager";
  };

  config = mkIf config.modules.desktop.hyprland.enable {
    # Environment variables
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };

    # System packages for Hyprland desktop environment
    environment.systemPackages = with pkgs; [
      # Waybar with experimental features
      (waybar.overrideAttrs (oldAttrs: {
        mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
      }))
      
      # Bluetooth
      bluez
      blueman
      
      # Themes and icons
      material-icons
      colloid-gtk-theme
      colloid-icon-theme
      catppuccin
      everforest-gtk-theme
      gruvbox-gtk-theme
      rose-pine-gtk-theme
      rose-pine-icon-theme
      
      # Desktop utilities
      libnotify
      swww
      wofi
      fish
      starship
      swaynotificationcenter
      wallust
      wayland-bongocat
      fastfetch
      powerline-fonts
      waytrogen
      imagemagick
      
      # System libraries
      glib
      gsettings-desktop-schemas
      dconf
    ];

    # Fonts
    fonts.packages = with pkgs; [
      nerd-fonts.fira-code
    ];

    # XDG portal configuration
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };

    # Services
    services = {
      # Bluetooth services
      blueman.enable = true;
    };

    hardware.bluetooth.enable = true;

    services = {
      
      
      # X11 configuration
      xserver.xkb.layout = "us";
      
      # Input devices
      libinput.enable = true;
    };

    # Programs
    programs = {
      dconf.enable = true;
      
      hyprland = {
        enable = true;
        xwayland.enable = true;
      };
      
      waybar = {
        enable = true;
      };
    };

    # Security and audio
    security = {
      polkit.enable = true;
      rtkit.enable = true;
    };

    # Pipewire audio
    services.pipewire = {
      enable = true;
      pulse.enable = true;
    };
  };
}
