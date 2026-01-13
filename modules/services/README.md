# Services Modules

This directory contains modules for system services and daemon configurations.

## Available Modules

### OpenSSH Server (`openssh.nix`)

Secure Shell server for remote access and administration.

#### Options

```nix
modules.services.openssh = {
  enable = true;  # Enable SSH server
  
  # Additional configuration options available
  # See openssh.nix for full option set
};
```

#### Features

- **Secure Remote Access**: Encrypted remote shell access
- **Key-Based Authentication**: Public key authentication support
- **Port Forwarding**: SSH tunneling capabilities
- **SFTP Support**: Secure file transfer protocol
- **Security Hardening**: Secure default configuration

#### Default Configuration

- Password authentication disabled (key-based only)
- Root login disabled
- Secure ciphers and key exchange algorithms
- Standard SSH port (22)

### Docker Service (`docker.nix`)

Container runtime and orchestration platform.

#### Options

```nix
modules.services.docker = {
  enable = true;  # Enable Docker service
  
  # Additional configuration options available
  # See docker.nix for full option set
};
```

#### Features

- **Container Runtime**: Run and manage containers
- **Image Management**: Build and manage container images
- **Network Management**: Container networking
- **Volume Management**: Persistent storage for containers
- **Docker Compose**: Multi-container application support

#### Default Configuration

- Docker daemon enabled
- User access configured
- Standard Docker socket
- Container networking enabled

## Default Configuration

The `default.nix` file in this directory:
- Imports all service modules
- Does not enable services by default (explicit opt-in required)
- Provides access to all service options

## Usage Examples

### Enable SSH Server
```nix
{
  imports = [ ./modules/services ];
  
  modules.services.openssh.enable = true;
}
```

### Enable Docker
```nix
{
  imports = [ ./modules/services ];
  
  modules.services.docker.enable = true;
  
  # Add user to docker group
  users.users.myuser.extraGroups = [ "docker" ];
}
```

### Enable Multiple Services
```nix
{
  imports = [ ./modules/services ];
  
  modules.services = {
    openssh.enable = true;
    docker.enable = true;
  };
}
```

## Service-Specific Information

### OpenSSH

**Security Features**
- Public key authentication only
- No root login allowed
- Secure cipher suites
- Connection rate limiting

**Usage**
```bash
# Connect to server
ssh user@hostname

# Copy files securely
scp file.txt user@hostname:/path/to/destination

# Port forwarding
ssh -L 8080:localhost:80 user@hostname
```

**Configuration**
- SSH keys: `~/.ssh/authorized_keys`
- Server config: `/etc/ssh/sshd_config`
- Client config: `~/.ssh/config`

### Docker

**Container Management**
```bash
# Run a container
docker run -d nginx

# List containers
docker ps

# Build an image
docker build -t myapp .

# Use Docker Compose
docker-compose up -d
```

**Storage and Networking**
- Volumes for persistent data
- Networks for container communication
- Port mapping for external access

**Development Workflow**
- Build development containers
- Mount source code volumes
- Use compose for multi-service apps

## Security Considerations

### SSH Security
- Use strong SSH keys (RSA 4096-bit or Ed25519)
- Regularly rotate SSH keys
- Monitor SSH access logs
- Consider fail2ban for brute force protection
- Use SSH agent for key management

### Docker Security
- Run containers as non-root users
- Use official base images
- Regularly update container images
- Limit container capabilities
- Use secrets management for sensitive data
- Monitor container resource usage

## Firewall Configuration

Services may require firewall rules:

```nix
# Allow SSH
networking.firewall.allowedTCPPorts = [ 22 ];

# Allow custom application ports
networking.firewall.allowedTCPPorts = [ 80 443 8080 ];

# Allow Docker networking
networking.firewall.trustedInterfaces = [ "docker0" ];
```

## Adding New Services

To add a new service module:

1. Create a new `.nix` file in this directory
2. Follow the existing module structure:
   ```nix
   { config, lib, pkgs, ... }:
   {
     options.modules.services.myservice = {
       enable = lib.mkEnableOption "My Service";
       # Additional options...
     };
     
     config = lib.mkIf config.modules.services.myservice.enable {
       # Service configuration...
     };
   }
   ```
3. Import the new module in `default.nix`
4. Update this README with documentation
5. Test the service functionality

## Troubleshooting

### SSH Issues

**Connection Refused**
- Check if SSH service is running: `systemctl status sshd`
- Verify firewall allows SSH: `sudo iptables -L`
- Check SSH configuration: `sudo sshd -T`

**Authentication Failed**
- Verify SSH key is in `~/.ssh/authorized_keys`
- Check key permissions (600 for private key, 644 for public key)
- Review SSH server logs: `journalctl -u sshd`

### Docker Issues

**Service Not Starting**
- Check Docker service status: `systemctl status docker`
- Review Docker logs: `journalctl -u docker`
- Verify user is in docker group: `groups $USER`

**Container Issues**
- Check container logs: `docker logs <container>`
- Verify image availability: `docker images`
- Check resource usage: `docker stats`

### Getting Help

- SSH: `man sshd_config`, `man ssh_config`
- Docker: https://docs.docker.com/
- NixOS services: https://nixos.org/manual/nixos/stable/
- System logs: `journalctl -u <service-name>`