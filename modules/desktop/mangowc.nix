{ config, lib, pkgs, inputs, ... }:

with lib;

{
  options.modules.desktop.mangowc = {
    enable = mkEnableOption "MangoWC compositor";
  };

  config = mkIf config.modules.desktop.mangowc.enable {
    environment.systemPackages = with pkgs;
      [
        inputs.mango.packages.${pkgs.system}.default
        foot
        wofi
        waybar
        swaybg
      ];
  };
}
