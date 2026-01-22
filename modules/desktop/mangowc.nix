{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.modules.desktop.mangowc;
in
{
  options.modules.desktop.mangowc = {
    enable = lib.mkEnableOption "mango window compositor";
  };

  imports = [
    inputs.mango.nixosModules.mango
  ];

  config = lib.mkIf cfg.enable {
    programs.mango.enable = true;

    environment.systemPackages = with pkgs; [
      foot
      wofi
      waybar
      swaybg
      swaynotificationcenter
      waytrogen 
      waybar 
      fcitx5 
      wl-clip-persist 
      sway-audio-idle-inhibit 
      hyprpolkitagent 
      udiskie 
      easyeffects 
      gnome-keyring
      swayidle 
      wlogout
    ];

    environment.etc."xsessions/mango.desktop".text = ''
      [Desktop Entry]
      Name=Mango
      Comment=Mango Wayland Compositor
      Exec=mango
      Type=Application
      DesktopNames=Mango
    '';
  };
}
