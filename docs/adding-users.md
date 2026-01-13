# Adding New Users

This guide explains how to add new users to your NixOS configuration using the modular user system.

## Overview

User configurations in this system are separated into:
- **System-level settings**: User accounts, groups, system packages
- **Home Manager settings**: User environment, dotfiles, user-specific programs
- **Host assignments**: Which users are available on which hosts

## Step-by-Step Process

### 1. Create User Directory

```bash
# Replace 'newuser' with the desired username
mkdir -p users/newuser
```

### 2. Copy User Templates

```bash
# Copy template files
cp users/templates/default-user.nix users/newuser/default.nix
cp users/templates/default-system.nix users/newuser/system.nix
cp users/templates/default-home.nix users/newuser/home.nix
```

### 3. Configure System-Level User Settings

Edit `users/newuser/system.nix`:

```nix
# users/newuser/system.nix
{ config, lib, pkgs, ... }:

{
  # System-level user configuration
  users.users.newuser = {
    isNormalUser = true;
    description = "New User Full Name";
    extraGroups = [ 
      "wheel"          # sudo access
      "networkmanager" # network management
      "audio"          # audio devices
      "video"          # video devices
      # Add other groups as needed:
      # "docker"       # Docker access
      # "libvirtd"     # Virtualization
      # "plugdev"      # USB devices
    ];
    
    # Set initial password (change on first login)
    initialPassword = "changeme";
    
    # OR use password hash (more secure)
    # hashedPassword = "$6$...";  # Generate with mkpasswd
    
    # OR disable password and use SSH keys only
    # hashedPassword = "!";  # Disable password login
    
    # SSH public keys for key-based authentication
    openssh.authorizedKeys.keys = [
      # "ssh-rsa AAAAB3NzaC1yc2E... user@hostname"
      # "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5... user@hostname"
    ];
    
    # User shell (optional, defaults to bash)
    shell = pkgs.bash;  # or pkgs.zsh, pkgs.fish, etc.
  };
  
  # System packages available to this user
  environment.systemPackages = with pkgs; [
    # Add user-specific system packages here
    # These are available system-wide but intended for this user
  ];
}
```

### 4. Configure Home Manager Settings

Edit `users/newuser/home.nix`:

```nix
# users/newuser/home.nix
{ config, lib, pkgs, ... }:

{
  # Home Manager configuration for newuser
  home = {
    username = "newuser";
    homeDirectory = "/home/newuser";
    stateVersion = "24.05";  # Set to your Home Manager version
    
    # User-specific packages
    packages = with pkgs; [
      # Command-line tools
      git
      vim
      htop
      tree
      curl
      wget
      
      # Development tools (if needed)
      # vscode
      # nodejs
      # python3
      
      # Desktop applications (if using desktop profile)
      # firefox
      # thunderbird
      # libreoffice
    ];
    
    # Environment variables
    sessionVariables = {
      EDITOR = "vim";
      BROWSER = "firefox";
      # Add other environment variables
    };
  };
  
  # Program configurations
  programs = {
    # Git configuration
    git = {
      enable = true;
      userName = "New User";
      userEmail = "newuser@example.com";
      extraConfig = {
        init.defaultBranch = "main";
        pull.rebase = true;
      };
    };
    
    # Bash configuration
    bash = {
      enable = true;
      bashrcExtra = ''
        # Custom bash configuration
        alias ll='ls -la'
        alias la='ls -A'
        alias l='ls -CF'
      '';
    };
    
    # Zsh configuration (alternative to bash)
    # zsh = {
    #   enable = true;
    #   enableCompletion = true;
    #   enableAutosuggestions = true;
    #   enableSyntaxHighlighting = true;
    # };
    
    # SSH client configuration
    ssh = {
      enable = true;
      # Add SSH client configuration here
    };
  };
  
  # Service configurations
  services = {
    # Enable user services as needed
    # gpg-agent = {
    #   enable = true;
    #   defaultCacheTtl = 1800;
    #   enableSshSupport = true;
    # };
  };
  
  # Dotfile management
  home.file = {
    # Example: custom configuration file
    # ".config/myapp/config.yaml".text = ''
    #   # Custom configuration content
    # '';
  };
  
  # XDG configuration (for desktop users)
  xdg = {
    enable = true;
    # Configure XDG directories and associations
  };
}
```

### 5. Configure Main User Module

Edit `users/newuser/default.nix`:

```nix
# users/newuser/default.nix
{ config, lib, pkgs, ... }:

{
  imports = [
    ./system.nix  # System-level user configuration
  ];
  
  # Home Manager configuration for this user
  home-manager.users.newuser = import ./home.nix;
  
  # Additional user-specific system configuration can go here
  # This is useful for system-level settings that are specific to this user
  # but don't belong in the system.nix file
}
```

### 6. Add User to Host Configuration

Edit the appropriate host's `users.nix` file (e.g., `hosts/thonkpad/users.nix`):

```nix
# hosts/thonkpad/users.nix
{ config, lib, pkgs, ... }:

{
  imports = [
    ../../users/jacob    # Existing user
    ../../users/newuser  # New user
  ];

  # Host-specific user overrides (if needed)
  users.users.newuser = {
    # Override user settings for this specific host
    extraGroups = [ "wheel" "networkmanager" "docker" ];  # Host-specific groups
  };
  
  # Enable sudo for wheel group
  security.sudo.wheelNeedsPassword = false;  # Adjust based on security needs
}
```

### 7. Build and Test

Test the configuration:

```bash
# Build without switching
sudo nixos-rebuild build --flake .#hostname

# If successful, switch to new configuration
sudo nixos-rebuild switch --flake .#hostname
```

## User Configuration Options

### User Account Types

**Normal User** (recommended for most users):
```nix
users.users.username = {
  isNormalUser = true;
  # ... other settings
};
```

**System User** (for services):
```nix
users.users.username = {
  isSystemUser = true;
  group = "username";
  # ... other settings
};
```

### Group Memberships

Common groups and their purposes:

```nix
extraGroups = [
  "wheel"          # sudo/admin access
  "networkmanager" # network configuration
  "audio"          # audio devices access
  "video"          # video devices access
  "docker"         # Docker daemon access
  "libvirtd"       # virtualization management
  "plugdev"        # USB and other plug devices
  "scanner"        # scanner access
  "lp"             # printer access
  "dialout"        # serial port access
  "cdrom"          # CD/DVD access
  "floppy"         # floppy disk access (legacy)
];
```

### Authentication Methods

**Password Authentication**:
```nix
# Set initial password (user should change)
initialPassword = "changeme";

# OR use hashed password
hashedPassword = "$6$rounds=4096$...";  # Generate with: mkpasswd -m sha-512
```

**SSH Key Authentication**:
```nix
openssh.authorizedKeys.keys = [
  "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQ... user@hostname"
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... user@hostname"
];

# Disable password authentication for security
hashedPassword = "!";  # This disables password login
```

**No Authentication** (for system users):
```nix
hashedPassword = "!";  # Disable login entirely
```

### Shell Configuration

```nix
# Set user shell
shell = pkgs.bash;     # Default
shell = pkgs.zsh;      # Z shell
shell = pkgs.fish;     # Fish shell
shell = pkgs.nushell;  # Nu shell
```

## Home Manager Configuration

### Program Configurations

**Git**:
```nix
programs.git = {
  enable = true;
  userName = "User Name";
  userEmail = "user@example.com";
  extraConfig = {
    init.defaultBranch = "main";
    pull.rebase = true;
    core.editor = "vim";
  };
};
```

**Shell (Bash)**:
```nix
programs.bash = {
  enable = true;
  bashrcExtra = ''
    # Custom aliases
    alias ll='ls -la'
    alias grep='grep --color=auto'
    
    # Custom functions
    mkcd() { mkdir -p "$1" && cd "$1"; }
  '';
  shellAliases = {
    ll = "ls -la";
    la = "ls -A";
    l = "ls -CF";
  };
};
```

**Shell (Zsh)**:
```nix
programs.zsh = {
  enable = true;
  enableCompletion = true;
  enableAutosuggestions = true;
  enableSyntaxHighlighting = true;
  oh-my-zsh = {
    enable = true;
    theme = "robbyrussell";
    plugins = [ "git" "sudo" "docker" ];
  };
};
```

**Text Editors**:
```nix
programs.vim = {
  enable = true;
  extraConfig = ''
    set number
    set relativenumber
    set tabstop=2
    set shiftwidth=2
    set expandtab
  '';
};

programs.neovim = {
  enable = true;
  defaultEditor = true;
  viAlias = true;
  vimAlias = true;
};
```

### Desktop Environment Configuration

For desktop users, configure desktop-specific settings:

```nix
# XDG configuration
xdg = {
  enable = true;
  userDirs = {
    enable = true;
    createDirectories = true;
  };
};

# Desktop applications
programs.firefox = {
  enable = true;
  # Firefox configuration
};

# File manager
programs.thunar.enable = true;

# Terminal emulator
programs.alacritty = {
  enable = true;
  settings = {
    window.opacity = 0.9;
    font.size = 12;
  };
};
```

## User Templates and Roles

### Developer User Template

For development-focused users:

```nix
# Enhanced development user configuration
home.packages = with pkgs; [
  # Development tools
  git
  vim
  vscode
  
  # Programming languages
  nodejs
  python3
  rustc
  cargo
  go
  
  # Development utilities
  docker
  docker-compose
  kubectl
  terraform
];

programs.git = {
  enable = true;
  # Git configuration for development
};

programs.ssh = {
  enable = true;
  # SSH configuration for accessing repositories
};
```

### Server Administrator Template

For server management users:

```nix
home.packages = with pkgs; [
  # System administration
  htop
  iotop
  nettools
  tcpdump
  nmap
  
  # Remote management
  tmux
  screen
  
  # Monitoring
  prometheus-node-exporter
];

programs.bash = {
  enable = true;
  bashrcExtra = ''
    # Server admin aliases
    alias syslog='journalctl -f'
    alias ports='netstat -tuln'
    alias processes='ps aux'
  '';
};
```

### Desktop User Template

For general desktop users:

```nix
home.packages = with pkgs; [
  # Desktop applications
  firefox
  thunderbird
  libreoffice
  gimp
  vlc
  
  # Utilities
  file-roller
  gnome.nautilus
];

programs.firefox.enable = true;
xdg.enable = true;
```

## Multi-Host User Management

### Host-Specific User Configuration

Users can have different configurations on different hosts:

```nix
# In hosts/desktop/users.nix
users.users.myuser.extraGroups = [ "wheel" "audio" "video" "docker" ];

# In hosts/server/users.nix  
users.users.myuser.extraGroups = [ "wheel" ];  # Minimal groups for server
```

### Conditional User Features

Enable features based on host profile:

```nix
# In user's home.nix
home.packages = with pkgs; [
  git
  vim
] ++ lib.optionals config.services.xserver.enable [
  # Desktop-only packages
  firefox
  vscode
];
```

## Security Considerations

### SSH Key Management

```bash
# Generate SSH key pair
ssh-keygen -t ed25519 -C "user@hostname"

# Add public key to user configuration
# Copy content of ~/.ssh/id_ed25519.pub to openssh.authorizedKeys.keys
```

### Password Security

```bash
# Generate secure password hash
mkpasswd -m sha-512

# Use the output in hashedPassword field
```

### Sudo Configuration

```nix
# Require password for sudo (more secure)
security.sudo.wheelNeedsPassword = true;

# Allow passwordless sudo (convenient but less secure)
security.sudo.wheelNeedsPassword = false;

# Custom sudo rules
security.sudo.extraRules = [
  {
    users = [ "myuser" ];
    commands = [
      {
        command = "/run/current-system/sw/bin/systemctl";
        options = [ "NOPASSWD" ];
      }
    ];
  }
];
```

## Troubleshooting

### Common Issues

**User Not Created**
- Check if user module is imported in host configuration
- Verify syntax in user configuration files
- Check build logs for errors

**Login Issues**
- Verify password or SSH key configuration
- Check user account status: `sudo passwd -S username`
- Review authentication logs: `journalctl -u sshd`

**Permission Issues**
- Check group memberships: `groups username`
- Verify file permissions in home directory
- Check sudo configuration

**Home Manager Issues**
- Verify Home Manager is properly configured in flake
- Check Home Manager logs: `journalctl --user -u home-manager-*`
- Test Home Manager configuration: `home-manager switch`

### Getting Help

- Home Manager manual: https://nix-community.github.io/home-manager/
- NixOS user management: https://nixos.org/manual/nixos/stable/#sec-user-management
- Check user configuration: `nixos-option users.users.username`

## Best Practices

1. **Use Templates**: Start with user templates and customize as needed
2. **Separate Concerns**: Keep system and user configurations separate
3. **Security First**: Use SSH keys and strong passwords
4. **Document Customizations**: Comment unusual configurations
5. **Test Changes**: Build and test before switching configurations
6. **Version Control**: Keep user configurations in version control
7. **Regular Updates**: Keep user packages and configurations updated
8. **Backup**: Backup important user data and configurations