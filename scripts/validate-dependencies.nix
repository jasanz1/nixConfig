# NixOS Module Dependency Validation Script
# This script validates that all module dependencies are properly resolved
# Requirements: 2.3 - Build system validation

{ pkgs ? import <nixpkgs> {} }:

let
  lib = pkgs.lib;
  
  # Helper function to extract imports from a Nix file
  extractImports = file: 
    let
      content = builtins.readFile file;
      # Simple regex-based extraction of import statements
      # This is a simplified approach - in practice, you'd want more robust parsing
      lines = lib.splitString "\n" content;
      importLines = builtins.filter (line: 
        lib.hasPrefix "  " line && 
        (lib.hasInfix "./" line || lib.hasInfix "../" line || lib.hasSuffix ".nix" line)
      ) lines;
    in importLines;
  
  # Function to validate a single module file
  validateModule = modulePath:
    let
      moduleDir = builtins.dirOf modulePath;
      imports = extractImports modulePath;
      
      # Check each import
      validateImport = importLine:
        let
          # Extract path from import line (simplified)
          cleanLine = lib.replaceStrings [" " ";" "\"" "'"] ["" "" "" ""] importLine;
          # This is a simplified path extraction
          importPath = if lib.hasPrefix "./" cleanLine 
                      then moduleDir + "/" + (lib.removePrefix "./" cleanLine)
                      else if lib.hasPrefix "../" cleanLine
                      then moduleDir + "/" + cleanLine
                      else cleanLine;
        in {
          import = importLine;
          path = importPath;
          exists = builtins.pathExists importPath;
        };
      
      importResults = map validateImport imports;
      
    in {
      module = modulePath;
      imports = importResults;
      valid = lib.all (result: result.exists) importResults;
    };
  
  # Function to find all .nix files in a directory
  findNixFiles = dir:
    if builtins.pathExists dir then
      let
        entries = builtins.readDir dir;
        nixFiles = lib.filterAttrs (name: type: 
          type == "regular" && lib.hasSuffix ".nix" name
        ) entries;
        subdirs = lib.filterAttrs (name: type: type == "directory") entries;
        
        currentFiles = map (name: dir + "/" + name) (lib.attrNames nixFiles);
        subFiles = lib.concatMap (name: findNixFiles (dir + "/" + name)) (lib.attrNames subdirs);
      in currentFiles ++ subFiles
    else [];
  
  # Main validation function
  validateConfiguration = configRoot:
    let
      modulesDir = configRoot + "/modules";
      hostsDir = configRoot + "/hosts";
      profilesDir = configRoot + "/profiles";
      usersDir = configRoot + "/users";
      
      # Find all Nix files
      moduleFiles = findNixFiles modulesDir;
      hostFiles = findNixFiles hostsDir;
      profileFiles = findNixFiles profilesDir;
      userFiles = findNixFiles usersDir;
      
      allFiles = moduleFiles ++ hostFiles ++ profileFiles ++ userFiles;
      
      # Validate each file
      results = map validateModule allFiles;
      
      # Summary
      validModules = builtins.filter (result: result.valid) results;
      invalidModules = builtins.filter (result: !result.valid) results;
      
    in {
      totalModules = builtins.length results;
      validModules = builtins.length validModules;
      invalidModules = builtins.length invalidModules;
      results = results;
      success = builtins.length invalidModules == 0;
    };

in {
  # Export the validation function
  validate = validateConfiguration;
  
  # Helper to run validation and format output
  runValidation = configRoot:
    let
      result = validateConfiguration configRoot;
      
      formatResult = moduleResult:
        let
          invalidImports = builtins.filter (imp: !imp.exists) moduleResult.imports;
        in if moduleResult.valid 
           then "✓ ${moduleResult.module}: All imports valid"
           else "✗ ${moduleResult.module}: Invalid imports: ${lib.concatStringsSep ", " (map (imp: imp.path) invalidImports)}";
      
      output = lib.concatStringsSep "\n" (map formatResult result.results);
      summary = "\nSummary: ${toString result.validModules}/${toString result.totalModules} modules valid";
      
    in output + summary;
}