# Template for system-level user configuration
{ username, extraGroups ? [], packages ? [] }:
{ config, lib, pkgs, ... }:

{
  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ] ++ extraGroups;
    packages = with pkgs; packages;
  };
}