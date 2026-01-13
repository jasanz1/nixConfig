# Template for creating new users
# Usage: Copy this directory structure to users/{username}/ and customize
{ username, extraGroups ? [], packages ? [] }:
{ config, lib, pkgs, inputs, ... }:

{
  # Import system-level user configuration
  imports = [
    ./system.nix
  ];

  # Home Manager configuration
  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users.${username} = import ./home.nix;
  };
}

# To create a new user:
# 1. Copy users/templates/ to users/{username}/
# 2. Rename default-user.nix to default.nix
# 3. Rename default-system.nix to system.nix  
# 4. Rename default-home.nix to home.nix
# 5. Customize the configurations for the specific user
# 6. Import the user in your host configuration