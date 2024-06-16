   
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
	rofi-wayland
	powerline-fonts
	nerdfonts
  ]; 
  fonts.packages = with pkgs; [
	(nerdfonts.override { fonts = ["FiraCode"]; })
];
  xdg.portal = {
  	enable = true;
	extraPortals = [pkgs.xdg-desktop-portal-gtk];
  };
  services.xserver.displayManager.gdm.enable = true;
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
