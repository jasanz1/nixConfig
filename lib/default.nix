{ pkgs }:

let
  inherit (pkgs.lib) mkOption types;
in
rec {
  # Helper function to validate host configuration requirements
  validateHostConfig = { hostname, profile, modules ? [] }:
    let
      # Note: In a real NixOS environment, this would check file existence
      # For now, we'll do basic validation of required parameters
      requiredParams = [ hostname profile ];
      validProfiles = [ "desktop" "server" "minimal" ];
      
    in
    if !(builtins.elem profile validProfiles) then
      throw "Invalid profile '${profile}'. Must be one of: ${builtins.toString validProfiles}"
    else if hostname == "" then
      throw "Hostname cannot be empty"
    else
      true;

  # Helper function to automatically load modules based on profile
  getProfileModules = profile:
    let
      profileModules = {
        desktop = [
          "modules/desktop"
          "modules/development" 
          "modules/services"
          "modules/system"
        ];
        server = [
          "modules/networking"
          "modules/security"
          "modules/services/openssh.nix"
          "modules/services/docker.nix"
          "modules/system"
        ];
        minimal = [
          "modules/system"
          "modules/security"
        ];
      };
    in
    profileModules.${profile} or (throw "Unknown profile: ${profile}");

  # Helper function to create host-specific module options
  mkHostOptions = {
    hostname = mkOption {
      type = types.str;
      description = "The hostname for this system";
    };
    
    profile = mkOption {
      type = types.enum [ "desktop" "server" "minimal" ];
      default = "desktop";
      description = "The system profile to use";
    };
    
    extraModules = mkOption {
      type = types.listOf types.path;
      default = [];
      description = "Additional modules to include for this host";
    };
    
    users = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "List of users to configure for this host";
    };
  };

  # Helper function to load user configurations
  loadUserConfigs = users:
    builtins.map (user: "users/${user}") users;

  # Validation function for module dependencies
  validateModuleDependencies = modules:
    let
      # Basic validation - ensure module list is valid
      invalidModules = builtins.filter (mod: 
        !(builtins.isString mod)
      ) modules;
    in
    if invalidModules != [] then
      throw "Invalid module specifications: ${builtins.toString invalidModules}"
    else
      modules;

  # Helper to merge host-specific and profile configurations
  mergeHostConfig = { hostname, profile, extraModules ? [], users ? [] }:
    let
      profileModules = getProfileModules profile;
      userModules = loadUserConfigs users;
      allModules = profileModules ++ extraModules ++ userModules;
      validatedModules = validateModuleDependencies allModules;
    in
    {
      inherit hostname profile;
      modules = validatedModules;
      isValid = validateHostConfig { inherit hostname profile; modules = allModules; };
    };
}