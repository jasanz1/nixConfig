# Development tools module
{ config, lib, pkgs, ... }:

with lib;

{
  options.modules.development.tools = {
    enable = mkEnableOption "development tools";
    
    git.enable = mkEnableOption "Git and related tools";
    containers.enable = mkEnableOption "container development tools";
    databases.enable = mkEnableOption "database tools";
    kubernetes.enable = mkEnableOption "Kubernetes tools";
    nix.enable = mkEnableOption "Nix development tools";
    ai.enable = mkEnableOption "AI development tools";
    cloudDev.enable = mkEnableOption "Cloud development tools";
  };

  config = mkIf config.modules.development.tools.enable {
    environment.systemPackages = with pkgs; [
      # Language servers and development utilities
      lua-language-server
      pkl
    ] ++ optionals config.modules.development.tools.git.enable [
      # Git tools
      git
      jujutsu
      lazygit
      gh
    ] ++ optionals config.modules.development.tools.containers.enable [
      # Container tools
      docker
      bootdev-cli
      distrobox
    ] ++ optionals config.modules.development.tools.databases.enable [
      # Database tools
      redis
      sqlite
    ] ++ optionals config.modules.development.tools.kubernetes.enable [
      # Kubernetes tools
      kubernetes
      minikube
    ] ++ optionals config.modules.development.tools.nix.enable [
      # Nix tools
      nurl
    ] ++ optionals config.modules.development.tools.ai.enable [
        opencode
    ] ++ optionals config.modules.development.tools.cloudDev.enable [
        terraform
        awscli2
    ];

    # Enable Docker service if containers are enabled
    virtualisation.docker.enable = mkIf config.modules.development.tools.containers.enable true;
  };
}
