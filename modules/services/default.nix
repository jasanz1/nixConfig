# Services modules default configuration
{ config, lib, pkgs, ... }:

{
  imports = [
    ./openssh.nix
    ./docker.nix
  ];
}