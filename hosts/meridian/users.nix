# User configuration for omen host
{ config, lib, pkgs, inputs, ... }:
{
  # Define user accounts
  users.users.jacob = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ]; # Enable 'sudo' for the user
    packages = with pkgs; [
      tree
    ];
  };

  # Home Manager configuration
  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users = {
      "jacob" = import ../../users/jacob/home.nix;
    };
  };

  # Git configuration
  programs.git = {
    enable = true;
  };
}
