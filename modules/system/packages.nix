# System packages module
{ config, lib, pkgs, ... }:

with lib;

{
  options.modules.system.packages = {
    enable = mkEnableOption "system packages";
    
    textEditing.enable = mkEnableOption "text editing tools";
    utilities.enable = mkEnableOption "system utilities";
    media.enable = mkEnableOption "media tools";
    networking.enable = mkEnableOption "networking tools";
    fileManagement.enable = mkEnableOption "file management tools";
  };

  config = mkIf config.modules.system.packages.enable {
    environment.systemPackages = with pkgs; [
      # Core system utilities (always included)
      coreutils
      vivaldi
      bash
      bc
      gawk
      unzip
      zip
    ] ++ optionals config.modules.system.packages.textEditing.enable [
      # Text editing
      obsidian
      vim
      neovim
      vimer
      tmux
      tmux-sessionizer
    ] ++ optionals config.modules.system.packages.utilities.enable [
      # System utilities
      lsof
      fzf
      bat
      ripgrep
      eza
      fd
      gdu
      bottom
      htop
      jq
      playerctl
      yazi
    ] ++ optionals config.modules.system.packages.media.enable [
      # Media tools
      mpv
      xclip
    ] ++ optionals config.modules.system.packages.networking.enable [
      # Networking tools
      wget
      net-tools
    ] ++ optionals config.modules.system.packages.fileManagement.enable [
      # File management
      kdePackages.dolphin
      kdePackages.konsole
    ];
  };
}
