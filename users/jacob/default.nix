# Jacob's user configuration
{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./system.nix  # System-level user configuration
  ];
  
  # Home Manager configuration
  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users.jacob = import ./home.nix;
  };
}