# Deep Configuration Comparison Tool
# Analyzes NixOS configurations at the Nix expression level
# Requirements: 5.1, 5.2, 5.3, 5.4, 5.5

{ pkgs ? import <nixpkgs> {} }:

let
  lib = pkgs.lib;
  
  # Helper function to safely evaluate a configuration file
  safeEval = configPath:
    if builtins.pathExists configPath then
      try (import configPath) {}
    else
      null;
  
  # Try to evaluate an expression, returning null on failure
  try = expr: default:
    let
      result = builtins.tryEval expr;
    in
      if result.success then result.value else default;
  
  # Extract all package references from a configuration
  extractPackages = config:
    let
      # Recursively find all package references
      findPackages = value:
        if builtins.isAttrs value then
          if value ? "pname" || value ? "name" then
            [ (value.pname or value.name or "unknown") ]
          else
            lib.concatLists (lib.mapAttrsToList (_: findPackages) value)
        else if builtins.isList value then
          lib.concatLists (map findPackages value)
        else
          [];
      
      packages = findPackages config;
    in
      lib.unique (lib.filter (pkg: pkg != "unknown" && pkg != "") packages);
  
  # Extract service configurations
  extractServices = config:
    let
      services = config.services or {};
      systemdServices = config.systemd.services or {};
      
      # Get enabled services
      enabledServices = lib.filterAttrs (_: service: 
        if builtins.isAttrs service then
          service.enable or false
        else
          false
      ) services;
      
      serviceNames = lib.attrNames enabledServices ++ lib.attrNames systemdServices;
    in
      lib.unique serviceNames;
  
  # Extract user configurations
  extractUsers = config:
    let
      users = config.users.users or {};
      homeManagerUsers = config.home-manager.users or {};
      
      userInfo = lib.mapAttrs (name: user: {
        inherit name;
        uid = user.uid or null;
        shell = user.shell or null;
        extraGroups = user.extraGroups or [];
        hasHomeManager = builtins.hasAttr name homeManagerUsers;
      }) users;
    in
      userInfo;
  
  # Extract system configuration options
  extractSystemConfig = config:
    {
      hostname = config.networking.hostName or null;
      timezone = config.time.timeZone or null;
      locale = config.i18n.defaultLocale or null;
      bootLoader = config.boot.loader or {};
      networking = {
        networkmanager = config.networking.networkmanager.enable or false;
        wireless = config.networking.wireless.enable or false;
        firewall = config.networking.firewall.enable or false;
      };
      desktop = {
        x11 = config.services.xserver.enable or false;
        wayland = config.programs.hyprland.enable or config.programs.sway.enable or false;
        displayManager = config.services.xserver.displayManager or {};
      };
    };
  
  # Compare two configuration extracts
  compareConfigs = original: restructured:
    let
      # Compare packages
      originalPackages = lib.sort lib.lessThan (extractPackages original);
      restructuredPackages = lib.sort lib.lessThan (extractPackages restructured);
      
      packageDiff = {
        added = lib.subtractLists originalPackages restructuredPackages;
        removed = lib.subtractLists restructuredPackages originalPackages;
        common = lib.intersectLists originalPackages restructuredPackages;
      };
      
      # Compare services
      originalServices = lib.sort lib.lessThan (extractServices original);
      restructuredServices = lib.sort lib.lessThan (extractServices restructured);
      
      serviceDiff = {
        added = lib.subtractLists originalServices restructuredServices;
        removed = lib.subtractLists restructuredServices originalServices;
        common = lib.intersectLists originalServices restructuredServices;
      };
      
      # Compare users
      originalUsers = extractUsers original;
      restructuredUsers = extractUsers restructured;
      
      userDiff = {
        added = lib.subtractLists (lib.attrNames originalUsers) (lib.attrNames restructuredUsers);
        removed = lib.subtractLists (lib.attrNames restructuredUsers) (lib.attrNames originalUsers);
        common = lib.intersectLists (lib.attrNames originalUsers) (lib.attrNames restructuredUsers);
      };
      
      # Compare system configuration
      originalSystem = extractSystemConfig original;
      restructuredSystem = extractSystemConfig restructured;
      
    in {
      packages = packageDiff;
      services = serviceDiff;
      users = userDiff;
      system = {
        original = originalSystem;
        restructured = restructuredSystem;
        hostnameChanged = originalSystem.hostname != restructuredSystem.hostname;
        timezoneChanged = originalSystem.timezone != restructuredSystem.timezone;
        localeChanged = originalSystem.locale != restructuredSystem.locale;
      };
    };
  
  # Format comparison results for human reading
  formatComparison = comparison:
    let
      formatList = title: items:
        if builtins.length items > 0 then
          "${title}:\n" + lib.concatStringsSep "\n" (map (item: "  - ${item}") items) + "\n"
        else
          "";
      
      formatSection = title: diff:
        "${title}:\n" +
        formatList "  Added" diff.added +
        formatList "  Removed" diff.removed +
        "  Common: ${toString (builtins.length diff.common)} items\n";
      
    in
      "Configuration Comparison Report\n" +
      "==============================\n\n" +
      formatSection "Packages" comparison.packages +
      "\n" +
      formatSection "Services" comparison.services +
      "\n" +
      formatSection "Users" comparison.users +
      "\n" +
      "System Configuration Changes:\n" +
      (if comparison.system.hostnameChanged then "  - Hostname changed\n" else "") +
      (if comparison.system.timezoneChanged then "  - Timezone changed\n" else "") +
      (if comparison.system.localeChanged then "  - Locale changed\n" else "") +
      "\n";
  
  # Main comparison function
  compareConfigurations = originalPath: restructuredPath:
    let
      # Load configurations
      originalConfig = safeEval originalPath;
      restructuredConfig = safeEval restructuredPath;
      
    in
      if originalConfig == null then
        { error = "Could not load original configuration from ${originalPath}"; }
      else if restructuredConfig == null then
        { error = "Could not load restructured configuration from ${restructuredPath}"; }
      else
        let
          comparison = compareConfigs originalConfig restructuredConfig;
          report = formatComparison comparison;
        in {
          success = true;
          comparison = comparison;
          report = report;
        };
  
  # Validate that a restructured configuration maintains functional equivalence
  validateEquivalence = originalPath: restructuredPath:
    let
      result = compareConfigurations originalPath restructuredPath;
    in
      if result ? error then
        result
      else
        let
          comp = result.comparison;
          
          # Check for critical differences
          criticalIssues = 
            (if builtins.length comp.packages.removed > 0 then ["Packages removed"] else []) ++
            (if builtins.length comp.services.removed > 0 then ["Services removed"] else []) ++
            (if builtins.length comp.users.removed > 0 then ["Users removed"] else []) ++
            (if comp.system.hostnameChanged then ["Hostname changed"] else []);
          
          # Check for acceptable changes
          acceptableChanges =
            (if builtins.length comp.packages.added > 0 then ["New packages added"] else []) ++
            (if builtins.length comp.services.added > 0 then ["New services added"] else []) ++
            (if builtins.length comp.users.added > 0 then ["New users added"] else []);
          
        in {
          success = true;
          equivalent = builtins.length criticalIssues == 0;
          criticalIssues = criticalIssues;
          acceptableChanges = acceptableChanges;
          report = result.report;
        };

in {
  # Export main functions
  compare = compareConfigurations;
  validate = validateEquivalence;
  
  # Helper function to run validation from command line
  runValidation = originalPath: restructuredPath:
    let
      result = validateEquivalence originalPath restructuredPath;
    in
      if result ? error then
        builtins.trace "ERROR: ${result.error}" false
      else if result.equivalent then
        builtins.trace "SUCCESS: Configurations are functionally equivalent" true
      else
        builtins.trace ("ISSUES FOUND:\n" + lib.concatStringsSep "\n" result.criticalIssues + "\n\n" + result.report) false;
}