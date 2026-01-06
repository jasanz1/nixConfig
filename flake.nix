{
  description = "Nixos config flake";

  inputs = {
    pkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    ghostty.url = "github:ghostty-org/ghostty";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "pkgs";
    };
  };

  outputs = { self, pkgs,ghostty, ... }@inputs: {
    nixosConfigurations.default = pkgs.lib.nixosSystem {
      specialArgs = {inherit inputs;};
      modules = [
        {environment.systemPackages = [
          ghostty.packages.x86_64-linux.default
        ];
        }
        ./configuration.nix
        inputs.home-manager.nixosModules.default
      ];
    };
  };
}
