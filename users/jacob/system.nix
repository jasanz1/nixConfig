# Jacob's system-level user configuration
{ config, lib, pkgs, ... }:

{
  users.users.jacob = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    packages = with pkgs; [
      tree
      discord
      zed
    ];
  };
}