{
  description = "Nixos config flake";

  inputs = {
    pkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    ghostty.url = "github:ghostty-org/ghostty";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "pkgs";
    };
    mango = {
      url = "github:DreamMaoMao/mango";
      inputs.nixpkgs.follows = "pkgs";
    };
  };

  outputs = { self, pkgs, ghostty, ... }@inputs:
    let
      customLib = import ./lib { inherit pkgs; };
      
      # Helper function to create a host configuration with validation
      mkHost = { hostname, system ? "x86_64-linux", profile ? "desktop", extraModules ? [], users ? [] }: 
        let
          # Validate host configuration before building
          hostConfig = customLib.mergeHostConfig { 
            inherit hostname profile extraModules users; 
          };
          
          # Get profile-specific modules automatically
          profileModules = customLib.getProfileModules profile;
          
          # Load user configurations
          userConfigs = customLib.loadUserConfigs users;
          
        in
        pkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { 
            inherit inputs; 
            lib = pkgs.lib // customLib;
          };
          modules = [
            # Global packages available to all hosts
            {
              environment.systemPackages = [
                ghostty.packages.${system}.default
              ];
            }
            # Host-specific configuration files
            ./hosts/${hostname}/configuration.nix
            ./hosts/${hostname}/hardware.nix
            ./hosts/${hostname}/users.nix
            # Profile-based configuration
            ./profiles/${profile}.nix
            # Home Manager integration
            inputs.home-manager.nixosModules.default
          ] ++ extraModules;
        };
    in
    {
      # Host configurations
      nixosConfigurations = {
        # Current host renamed from "default" to "thonkpad"
        thonkpad = mkHost {
          hostname = "thonkpad";
          profile = "desktop";
        };
        
        meridian = mkHost {
          hostname = "meridian";
          profile = "desktop";
        };
        
        # Example of how to add additional hosts
        # server-example = mkHost {
        #   hostname = "server-example";
        #   profile = "server";
        # };
      };
      
      # Expose the helper functions for easy host addition
      lib = customLib // {
        inherit mkHost;
      };
    };
}
