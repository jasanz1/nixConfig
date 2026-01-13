# Docker service module
{ config, lib, pkgs, ... }:

{
  options.modules.services.docker.enable = lib.mkEnableOption "Docker service";

  config = lib.mkIf config.modules.services.docker.enable {
    virtualisation.docker.enable = true;
  };
}