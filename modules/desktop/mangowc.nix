{ config, lib, pkgs, ... }:

with lib;

{
  options.modules.desktop.mangowc = {
    enable = mkEnableOption "MangoWC compositor";
  };

  config = mkIf config.modules.desktop.mangowc.enable {
    programs.mango.enable = true;

    environment.systemPackages = with pkgs;
      [
        foot
        wofi
        waybar
        swaybg
      ];
  };
}
