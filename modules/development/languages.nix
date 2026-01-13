# Programming languages module
{ config, lib, pkgs, ... }:

with lib;

{
  options.modules.development.languages = {
    enable = mkEnableOption "programming languages";
    
    rust.enable = mkEnableOption "Rust development environment";
    go.enable = mkEnableOption "Go development environment";
    nodejs.enable = mkEnableOption "Node.js development environment";
    python.enable = mkEnableOption "Python development environment";
    erlang.enable = mkEnableOption "Erlang development environment";
    elixir.enable = mkEnableOption "Elixir development environment (includes Erlang)";
    zig.enable = mkEnableOption "Zig development environment";
    gleam.enable = mkEnableOption "Gleam development environment (includes Erlang)";
  };

  config = mkIf config.modules.development.languages.enable {
    environment.systemPackages = with pkgs; [
      # Build tools
      gcc
      gnumake
      cmake
      tree-sitter
    ] ++ optionals config.modules.development.languages.rust.enable [
      # Rust
      cargo
      rustc
    ] ++ optionals config.modules.development.languages.go.enable [
      # Go
      go
    ] ++ optionals config.modules.development.languages.nodejs.enable [
      # Node.js
      nodejs_22
      pnpm
    ] ++ optionals config.modules.development.languages.python.enable [
      # Python
      python3
      pipenv
    ] ++ optionals (config.modules.development.languages.erlang.enable || 
                    config.modules.development.languages.elixir.enable || 
                    config.modules.development.languages.gleam.enable) [
      # Erlang (shared dependency for Elixir and Gleam)
      erlang_27
    ] ++ optionals config.modules.development.languages.elixir.enable [
      # Elixir (requires Erlang)
      elixir
      elixir-ls
      rebar3
    ] ++ optionals config.modules.development.languages.gleam.enable [
      # Gleam (requires Erlang)
      gleam
    ] ++ optionals config.modules.development.languages.zig.enable [
      # Zig
      zig
    ];
  };
}