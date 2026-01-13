# Development modules default configuration
{ config, lib, pkgs, ... }:

{
  imports = [
    ./languages.nix
    ./tools.nix
  ];

  # Enable development tools by default
  modules.development.languages = {
    enable = lib.mkDefault true;
    rust.enable = lib.mkDefault true;
    go.enable = lib.mkDefault true;
    nodejs.enable = lib.mkDefault true;
    python.enable = lib.mkDefault true;
    elixir.enable = lib.mkDefault true;  # This will automatically include Erlang
    zig.enable = lib.mkDefault true;
    gleam.enable = lib.mkDefault true;   # This will also use the shared Erlang
  };

  modules.development.tools = {
    enable = lib.mkDefault true;
    git.enable = lib.mkDefault true;
    containers.enable = lib.mkDefault true;
    databases.enable = lib.mkDefault true;
    kubernetes.enable = lib.mkDefault true;
    nix.enable = lib.mkDefault true;
  };
}