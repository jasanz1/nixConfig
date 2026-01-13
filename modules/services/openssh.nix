# OpenSSH service module
{ config, lib, pkgs, ... }:

{
  # Enable the OpenSSH daemon
  services.openssh.enable = true;
}