   
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
	dunst
	libnotify
	swww
	rofi
	powerline-fonts
	# nerdfonts
  ]; 
  fonts.packages = with pkgs; [
		nerd-fonts.fira-code
	];
  xdg.portal = {
  	enable = true;
	extraPortals = [pkgs.xdg-desktop-portal-gtk];
  };

  services.xserver = {	
	enable = true;
	displayManager.gdm = {
		enable = true;
		wayland = true;
		};
	};
  programs = { 
	hyprland = {
	  enable = true;
	  xwayland.enable = true;
	};
	waybar = {
		  enable = true;
	};
 };
}
