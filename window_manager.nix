   
{ config, lib, pkgs, ... }:
{
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };
  environment.systemPackages = with pkgs; [
	(waybar.overrideAttrs (oldAttrs: {
		mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true"];
		})
	)
		bluez
		blueman
		material-icons
		colloid-gtk-theme      # GTK theme package
    colloid-icon-theme
		catppuccin
		everforest-gtk-theme
		gruvbox-gtk-theme
		rose-pine-gtk-theme
		rose-pine-icon-theme
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
		glib
		gsettings-desktop-schemas
		dconf
	# nerdfonts
  ]; 
  fonts.packages = with pkgs; [
		nerd-fonts.fira-code
	];
  xdg.portal = {
  	enable = true;
	extraPortals = [pkgs.xdg-desktop-portal-gtk];
  };
	services = {
		displayManager.gdm = {
			enable = true;
			wayland = true;
		};
	};
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
}
