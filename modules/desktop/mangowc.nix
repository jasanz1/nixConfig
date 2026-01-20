{ config, lib, pkgs, inputs, ... }:

with lib;

{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    mango = {
      url = "github:DreamMaoMao/mango";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    inputs@{ self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      debug = true;
      systems = [ "x86_64-linux" ];
      flake = {
        nixosConfigurations = {
          hostname = inputs.nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              inputs.mango.nixosModules.mango
              {
                programs.mango.enable = true;
                environment.systemPackages = with pkgs; [
                  foot
                  wofi
                  waybar
                  swaybg
                ];
              }
            ];
          };
        };
      };
    };
}
