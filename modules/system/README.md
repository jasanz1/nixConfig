# System Modules

This directory contains modules for core system configuration and system-wide packages.

## Available Modules

### System Packages (`packages.nix`)

Manages system-wide packages organized by category.

#### Package Categories

- **Text Editing**: Editors and text processing tools
- **Utilities**: System utilities and command-line tools
- **Media**: Audio, video, and image processing tools
- **Networking**: Network utilities and tools
- **File Management**: File managers and archive tools

#### Options

```nix
modules.system.packages = {
  enable = true;  # Enable system packages
  
  textEditing.enable = true;     # Text editors and tools
  utilities.enable = true;       # System utilities
  media.enable = true;           # Media tools
  networking.enable = true;      # Network tools
  fileManagement.enable = true;  # File management tools
};
```

## Default Configuration

The `default.nix` file in this directory:
- Imports all system modules
- Enables all package categories by default
- Provides sensible defaults for system configuration

## Package Categories Detail

### Text Editing
Essential text editors and processing tools:
- **vim/neovim**: Advanced text editors
- **nano**: Simple text editor
- **emacs**: Extensible text editor
- **Text processing tools**: sed, awk, grep, etc.

### Utilities
Core system utilities:
- **Process management**: htop, ps, kill
- **File operations**: find, locate, tree
- **Archive tools**: tar, zip, unzip
- **System monitoring**: iostat, netstat, lsof
- **Network utilities**: wget, curl, rsync

### Media
Audio, video, and image tools:
- **Audio tools**: alsa-utils, pulseaudio-utils
- **Video tools**: ffmpeg, vlc (if GUI enabled)
- **Image tools**: imagemagick, gimp (if GUI enabled)
- **Codecs**: Various audio/video codecs

### Networking
Network configuration and diagnostic tools:
- **Network configuration**: iproute2, net-tools
- **Diagnostic tools**: ping, traceroute, nmap
- **Transfer tools**: wget, curl, rsync
- **Monitoring tools**: iftop, nethogs

### File Management
File system and archive management:
- **File managers**: ranger, mc (text-based)
- **Archive tools**: tar, zip, 7zip, rar
- **File utilities**: file, tree, du, df
- **Synchronization**: rsync, rclone

## Usage Examples

### Full System Package Set
```nix
{
  imports = [ ./modules/system ];
  
  # All package categories enabled by default
}
```

### Selective Package Categories
```nix
{
  imports = [ ./modules/system ];
  
  modules.system.packages = {
    enable = true;
    textEditing.enable = true;
    utilities.enable = true;
    media.enable = false;        # Disable media tools
    networking.enable = true;
    fileManagement.enable = false; # Disable file management
  };
}
```

### Minimal System Packages
```nix
{
  imports = [ ./modules/system ];
  
  modules.system.packages = {
    enable = true;
    textEditing.enable = true;   # Only text editing
    utilities.enable = false;
    media.enable = false;
    networking.enable = false;
    fileManagement.enable = false;
  };
}
```

### Adding Custom Packages
```nix
{
  imports = [ ./modules/system ];
  
  # System module packages
  modules.system.packages.enable = true;
  
  # Additional custom packages
  environment.systemPackages = with pkgs; [
    my-custom-tool
    another-package
  ];
}
```

## Package Management

### System vs User Packages

**System Packages** (this module):
- Available to all users
- Installed system-wide
- Managed by root/administrator
- Persistent across user sessions

**User Packages** (Home Manager):
- Available to specific user only
- Installed in user profile
- Managed by individual users
- User-specific configuration

### Package Categories Philosophy

**Text Editing**: Essential for system administration and development
**Utilities**: Core tools needed for system operation and maintenance
**Media**: Tools for handling multimedia content (optional for servers)
**Networking**: Network diagnostic and configuration tools
**File Management**: Tools for organizing and managing files

## Configuration Customization

### Override Package Selections
```nix
# In your host configuration
modules.system.packages = {
  enable = true;
  # Enable specific categories
  textEditing.enable = true;
  utilities.enable = true;
  
  # Override specific packages (if module supports it)
  # Check packages.nix for available overrides
};
```

### Profile-Specific Packages

Different profiles include different package sets:

**Desktop Profile**: All categories enabled
**Server Profile**: Limited to essential categories
**Minimal Profile**: Only basic text editing and utilities

## Adding New Package Categories

To add a new package category:

1. Edit `packages.nix`
2. Add new option in the options section:
   ```nix
   newCategory.enable = lib.mkEnableOption "New Category packages";
   ```
3. Add configuration logic:
   ```nix
   environment.systemPackages = lib.optionals config.modules.system.packages.newCategory.enable [
     # Package list
   ];
   ```
4. Update `default.nix` to enable by default if appropriate
5. Update this README with documentation

## Troubleshooting

### Package Not Found
- Check if category is enabled
- Verify package name: `nix search nixpkgs <package-name>`
- Check if package is available in current nixpkgs version

### Package Conflicts
- Review package dependencies
- Check for conflicting package versions
- Use `nix-env --query` to see installed packages

### Missing Dependencies
- Ensure all required categories are enabled
- Check if package needs additional system configuration
- Review package documentation for requirements

### Performance Issues
- Consider disabling unused package categories
- Use `nix-collect-garbage` to clean up old packages
- Monitor disk usage with `du -sh /nix/store`

## Getting Help

- NixOS package search: https://search.nixos.org/packages
- Package documentation: `nix-env --query --description`
- NixOS manual: https://nixos.org/manual/nixos/stable/
- Package issues: Check package's upstream documentation