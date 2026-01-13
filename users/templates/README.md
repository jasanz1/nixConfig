# User Configuration Templates

This directory contains templates for creating new user configurations in the NixOS system.

## Template Files

- `default-user.nix` - Main user configuration template that imports system and home configurations
- `default-system.nix` - System-level user configuration template (user account, groups, system packages)
- `default-home.nix` - Home Manager configuration template (user environment, dotfiles, programs)

## Creating a New User

1. Copy the entire `templates/` directory to `users/{username}/`
2. Rename the template files:
   - `default-user.nix` → `default.nix`
   - `default-system.nix` → `system.nix`
   - `default-home.nix` → `home.nix`
3. Edit the files to customize for the specific user:
   - Update username references
   - Add user-specific packages
   - Configure user-specific programs and settings
4. Import the user configuration in your host configuration or main user file

## File Structure

```
users/
├── {username}/
│   ├── default.nix    # Main user module (imports system.nix and configures Home Manager)
│   ├── system.nix     # System-level user settings (account, groups, system packages)
│   └── home.nix       # Home Manager configuration (user environment, dotfiles)
└── templates/         # Template files for creating new users
```

## Example Usage

To create a user named "alice":

```bash
cp -r users/templates users/alice
cd users/alice
mv default-user.nix default.nix
mv default-system.nix system.nix
mv default-home.nix home.nix
# Edit the files to customize for alice
```

Then import in your configuration:
```nix
imports = [
  ./users/alice
];
```