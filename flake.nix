{
  description = "Nixos config flake";

  inputs = {
    pkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    ghostty.url = "github:ghostty-org/ghostty";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "pkgs-unstable";
    };
  };

  outputs = { self, pkgs-unstable,ghostty, ... }@inputs: {
    nixosConfigurations.default = pkgs-unstable.lib.nixosSystem {
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
