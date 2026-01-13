# Development Modules

This directory contains modules for development tools, programming languages, and development environments.

## Available Modules

### Programming Languages (`languages.nix`)

Support for multiple programming languages and their toolchains.

#### Supported Languages

- **Rust**: Complete Rust toolchain with Cargo
- **Go**: Go compiler and tools
- **Node.js**: JavaScript runtime and npm
- **Python**: Python interpreter and pip
- **Elixir**: Elixir language with Erlang VM
- **Zig**: Zig compiler and toolchain
- **Gleam**: Gleam language (uses shared Erlang)

#### Options

```nix
modules.development.languages = {
  enable = true;  # Enable language support
  
  rust.enable = true;     # Rust toolchain
  go.enable = true;       # Go compiler
  nodejs.enable = true;   # Node.js runtime
  python.enable = true;   # Python interpreter
  elixir.enable = true;   # Elixir + Erlang
  zig.enable = true;      # Zig compiler
  gleam.enable = true;    # Gleam language
};
```

### Development Tools (`tools.nix`)

Essential development tools and utilities.

#### Available Tools

- **Git**: Version control system
- **Containers**: Docker and container tools
- **Databases**: Database clients and tools
- **Kubernetes**: Container orchestration tools
- **Nix**: Nix development tools

#### Options

```nix
modules.development.tools = {
  enable = true;  # Enable development tools
  
  git.enable = true;         # Git version control
  containers.enable = true;  # Docker and container tools
  databases.enable = true;   # Database tools
  kubernetes.enable = true;  # Kubernetes tools
  nix.enable = true;         # Nix development tools
};
```

## Default Configuration

The `default.nix` file in this directory:
- Imports all development modules
- Enables all languages and tools by default
- Provides sensible defaults for development environments

## Usage Examples

### Full Development Environment
```nix
{
  imports = [ ./modules/development ];
  
  # All development tools enabled by default
  # Customize as needed
}
```

### Selective Language Support
```nix
{
  imports = [ ./modules/development ];
  
  modules.development.languages = {
    enable = true;
    rust.enable = true;
    python.enable = true;
    nodejs.enable = false;  # Disable Node.js
    go.enable = false;      # Disable Go
  };
}
```

### Minimal Development Setup
```nix
{
  imports = [ ./modules/development ];
  
  modules.development = {
    languages.enable = false;  # Disable all languages
    tools = {
      enable = true;
      git.enable = true;       # Only Git
      containers.enable = false;
      databases.enable = false;
      kubernetes.enable = false;
    };
  };
}
```

## Language-Specific Information

### Rust
- Includes rustc, cargo, rustfmt, clippy
- Rust analyzer for IDE support
- Cross-compilation targets available

### Go
- Go compiler and standard library
- Go modules support
- Development tools (gofmt, golint, etc.)

### Node.js
- Node.js runtime
- npm package manager
- Yarn alternative package manager

### Python
- Python 3 interpreter
- pip package manager
- Virtual environment support
- Common development packages

### Elixir
- Elixir language
- Erlang VM (shared with Gleam)
- Mix build tool
- Phoenix framework support

### Zig
- Zig compiler
- Standard library
- Cross-compilation support

### Gleam
- Gleam compiler
- Erlang VM (shared with Elixir)
- Package manager

## Development Tools Information

### Git
- Git version control system
- Common Git utilities
- Configuration helpers

### Containers
- Docker engine and CLI
- Docker Compose
- Container development tools

### Databases
- Database clients (PostgreSQL, MySQL, etc.)
- Database administration tools
- Development database utilities

### Kubernetes
- kubectl command-line tool
- Helm package manager
- Development cluster tools

### Nix
- Nix development tools
- Flake utilities
- Package development helpers

## Adding New Languages or Tools

To add a new language or tool:

1. Edit the appropriate module file (`languages.nix` or `tools.nix`)
2. Add new options following the existing pattern
3. Implement the configuration logic
4. Update this README with documentation
5. Test the new functionality

## Troubleshooting

### Language Issues
- Check if language is enabled in configuration
- Verify package installation with `which <command>`
- Review environment variables and PATH

### Tool Issues
- Ensure tools are enabled in configuration
- Check service status for daemon-based tools
- Verify permissions for development tools

### Container Issues
- Check Docker service status: `systemctl status docker`
- Verify user is in docker group
- Check container runtime configuration

### Getting Help
- Language-specific documentation and communities
- NixOS package search: https://search.nixos.org/packages
- Development tool documentation