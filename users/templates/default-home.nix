# Template for Home Manager configuration
{ username }:
{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = username;
  home.homeDirectory = "/home/${username}";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  home.stateVersion = "24.05"; # Please read the comment before changing.

  # Default packages for all users
  home.packages = [
    # Add common packages here
  ];

  # Default dotfiles configuration
  home.file = {
    # Add common dotfiles here
  };

  # Default session configuration
  home.sessionPath = [
    "$HOME/.cargo/bin"
  ];

  # Default programs configuration
  programs = { 
    fzf = {
      enable = true;
      enableFishIntegration = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
    };
    bash = {
      enable = true;
      enableCompletion = true;
      shellAliases = {
        nixRebuild = "sudo nixos-rebuild switch --flake /etc/nixos/#$(hostname)";
        nixConfig = "cd /etc/nixos/";
        config = "cd ~/.config/";
        vim = "nvim";
        cat = "bat";
        grep = "rg";
        ls = "exa";
        tree = "exa --tree";
        find = "fd";
      };
    };
    neovim = {
      enable = true;
      defaultEditor = true;
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}