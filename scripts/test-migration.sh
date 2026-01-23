#!/usr/bin/env bash

# Automated Migration Testing Script
# Tests that the restructured configuration builds and functions correctly
# Requirements: 5.1, 5.2, 5.3, 5.4, 5.5

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_ROOT="${1:-$(dirname "$SCRIPT_DIR")}"
BACKUP_DIR="${2:-}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

log_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

log_error() {
    echo -e "${RED}✗ $1${NC}" >&2
    ((FAILED_TESTS++))
}

log_success() {
    echo -e "${GREEN}✓ $1${NC}"
    ((PASSED_TESTS++))
}

log_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

log_info() {
    echo "INFO: $1"
}

start_test() {
    ((TOTAL_TESTS++))
    log_info "Starting test: $1"
}

# Test that flake can be evaluated
test_flake_evaluation() {
    start_test "Flake Evaluation"
    
    if [[ ! -f "$CONFIG_ROOT/flake.nix" ]]; then
        log_error "flake.nix not found"
        return 1
    fi
    
    if nix flake check "$CONFIG_ROOT" --no-build 2>/dev/null; then
        log_success "Flake evaluation successful"
        return 0
    else
        log_error "Flake evaluation failed"
        return 1
    fi
}

# Test that configuration can be built (dry-run)
test_configuration_build() {
    start_test "Configuration Build (Dry Run)"
    
    # Get the first available system configuration
    local systems=$(nix flake show "$CONFIG_ROOT" --json 2>/dev/null | jq -r '.nixosConfigurations | keys[]' 2>/dev/null || echo "")
    
    if [[ -z "$systems" ]]; then
        log_error "No NixOS configurations found in flake"
        return 1
    fi
    
    local first_system=$(echo "$systems" | head -n1)
    log_info "Testing build for system: $first_system"
    
    if nix build "$CONFIG_ROOT#nixosConfigurations.$first_system.config.system.build.toplevel" --dry-run 2>/dev/null; then
        log_success "Configuration build test passed"
        return 0
    else
        log_error "Configuration build test failed"
        return 1
    fi
}

# Test that all modules can be imported
test_module_imports() {
    start_test "Module Import Test"
    
    local modules_dir="$CONFIG_ROOT/modules"
    local failed_modules=()
    
    if [[ ! -d "$modules_dir" ]]; then
        log_error "Modules directory not found"
        return 1
    fi
    
    # Test each module file
    while IFS= read -r -d '' module_file; do
        local module_name=$(basename "$module_file")
        
        # Create a minimal test configuration that imports the module
        local test_config=$(mktemp)
        cat > "$test_config" << EOF
{ config, lib, pkgs, ... }:
{
  imports = [ $module_file ];
}
EOF
        
        # Test if the module can be parsed
        if nix-instantiate --eval --expr "import $test_config { config = {}; lib = (import <nixpkgs> {}).lib; pkgs = import <nixpkgs> {}; }" &>/dev/null; then
            log_info "Module $module_name imports successfully"
        else
            failed_modules+=("$module_name")
        fi
        
        rm -f "$test_config"
        
    done < <(find "$modules_dir" -name "*.nix" -type f -print0)
    
    if [[ ${#failed_modules[@]} -eq 0 ]]; then
        log_success "All modules import successfully"
        return 0
    else
        log_error "Failed to import modules: ${failed_modules[*]}"
        return 1
    fi
}

# Test that profiles are valid
test_profiles() {
    start_test "Profile Validation"
    
    local profiles_dir="$CONFIG_ROOT/profiles"
    local failed_profiles=()
    
    if [[ ! -d "$profiles_dir" ]]; then
        log_error "Profiles directory not found"
        return 1
    fi
    
    for profile_file in "$profiles_dir"/*.nix; do
        if [[ -f "$profile_file" ]]; then
            local profile_name=$(basename "$profile_file" .nix)
            
            # Test if the profile can be parsed
            if nix-instantiate --parse "$profile_file" &>/dev/null; then
                log_info "Profile $profile_name is valid"
            else
                failed_profiles+=("$profile_name")
            fi
        fi
    done
    
    if [[ ${#failed_profiles[@]} -eq 0 ]]; then
        log_success "All profiles are valid"
        return 0
    else
        log_error "Invalid profiles: ${failed_profiles[*]}"
        return 1
    fi
}

# Test that user configurations are valid
test_user_configurations() {
    start_test "User Configuration Validation"
    
    local users_dir="$CONFIG_ROOT/users"
    local failed_users=()
    
    if [[ ! -d "$users_dir" ]]; then
        log_error "Users directory not found"
        return 1
    fi
    
    # Test each user directory
    for user_dir in "$users_dir"/*; do
        if [[ -d "$user_dir" && "$(basename "$user_dir")" != "templates" ]]; then
            local user_name=$(basename "$user_dir")
            local user_valid=true
            
            # Check for required files
            for required_file in "default.nix" "home.nix" "system.nix"; do
                if [[ -f "$user_dir/$required_file" ]]; then
                    if ! nix-instantiate --parse "$user_dir/$required_file" &>/dev/null; then
                        user_valid=false
                        break
                    fi
                fi
            done
            
            if $user_valid; then
                log_info "User $user_name configuration is valid"
            else
                failed_users+=("$user_name")
            fi
        fi
    done
    
    if [[ ${#failed_users[@]} -eq 0 ]]; then
        log_success "All user configurations are valid"
        return 0
    else
        log_error "Invalid user configurations: ${failed_users[*]}"
        return 1
    fi
}

# Test that host configurations are complete
test_host_configurations() {
    start_test "Host Configuration Completeness"
    
    local hosts_dir="$CONFIG_ROOT/hosts"
    local failed_hosts=()
    
    if [[ ! -d "$hosts_dir" ]]; then
        log_error "Hosts directory not found"
        return 1
    fi
    
    for host_dir in "$hosts_dir"/*; do
        if [[ -d "$host_dir" ]]; then
            local host_name=$(basename "$host_dir")
            local host_valid=true
            
            # Check for required files
            local required_files=("configuration.nix" "hardware.nix" "users.nix")
            for required_file in "${required_files[@]}"; do
                if [[ ! -f "$host_dir/$required_file" ]]; then
                    host_valid=false
                    break
                fi
                
                # Test syntax
                if ! nix-instantiate --parse "$host_dir/$required_file" &>/dev/null; then
                    host_valid=false
                    break
                fi
            done
            
            if $host_valid; then
                log_info "Host $host_name configuration is complete"
            else
                failed_hosts+=("$host_name")
            fi
        fi
    done
    
    if [[ ${#failed_hosts[@]} -eq 0 ]]; then
        log_success "All host configurations are complete"
        return 0
    else
        log_error "Incomplete host configurations: ${failed_hosts[*]}"
        return 1
    fi
}

# Run functional equivalence test using deep comparison
test_functional_equivalence() {
    start_test "Functional Equivalence Test"
    
    if [[ -z "$BACKUP_DIR" ]]; then
        log_warning "No backup directory provided, skipping equivalence test"
        return 0
    fi
    
    if [[ ! -f "$SCRIPT_DIR/deep-compare.nix" ]]; then
        log_error "Deep comparison tool not found"
        return 1
    fi
    
    local original_config="$BACKUP_DIR/configuration.nix"
    local new_config="$CONFIG_ROOT/hosts/thonkpad/configuration.nix"
    
    if [[ ! -f "$original_config" ]]; then
        log_error "Original configuration not found: $original_config"
        return 1
    fi
    
    if [[ ! -f "$new_config" ]]; then
        log_error "New configuration not found: $new_config"
        return 1
    fi
    
    # Run the deep comparison
    local nix_expr="
    let
      compareTool = import $SCRIPT_DIR/deep-compare.nix {};
      result = compareTool.runValidation \"$original_config\" \"$new_config\";
    in
      result
    "
    
    if nix-instantiate --eval --expr "$nix_expr" &>/dev/null; then
        log_success "Functional equivalence test passed"
        return 0
    else
        log_error "Functional equivalence test failed"
        return 1
    fi
}

# Generate test report
generate_test_report() {
    log_header "Migration Test Report"
    
    echo "Configuration Root: $CONFIG_ROOT"
    echo "Backup Directory: ${BACKUP_DIR:-"Not provided"}"
    echo "Test Date: $(date)"
    echo ""
    
    # Run all tests
    test_flake_evaluation
    test_configuration_build
    test_module_imports
    test_profiles
    test_user_configurations
    test_host_configurations
    test_functional_equivalence
    
    echo ""
    log_header "Test Summary"
    echo "Total Tests: $TOTAL_TESTS"
    echo "Passed: $PASSED_TESTS"
    echo "Failed: $FAILED_TESTS"
    
    local success_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    echo "Success Rate: $success_rate%"
    echo ""
    
    if [[ $FAILED_TESTS -eq 0 ]]; then
        log_success "All migration tests passed!"
        echo "The restructured configuration appears to be working correctly."
        return 0
    else
        log_error "Some migration tests failed"
        echo "Please review the issues above before proceeding."
        return 1
    fi
}

# Find backup directory automatically if not provided
find_backup_dir() {
    if [[ -n "$BACKUP_DIR" && -d "$BACKUP_DIR" ]]; then
        echo "$BACKUP_DIR"
        return 0
    fi
    
    # Look for backup directories in the config root
    local backup_pattern="backup-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9]"
    local found_backup=""
    
    for dir in "$CONFIG_ROOT"/$backup_pattern; do
        if [[ -d "$dir" ]]; then
            found_backup="$dir"
            break
        fi
    done
    
    if [[ -n "$found_backup" ]]; then
        echo "$found_backup"
        return 0
    else
        echo ""
        return 1
    fi
}

# Main function
main() {
    echo "NixOS Configuration Migration Testing"
    echo "===================================="
    echo ""
    
    # Find backup directory if not provided
    if [[ -z "$BACKUP_DIR" ]]; then
        if BACKUP_DIR=$(find_backup_dir); then
            log_info "Found backup directory: $BACKUP_DIR"
        else
            log_warning "No backup directory found - some tests will be skipped"
        fi
    fi
    
    # Check prerequisites
    if ! command -v nix &> /dev/null; then
        log_error "Nix is required but not found in PATH"
        exit 1
    fi
    
    # Run tests
    if generate_test_report; then
        exit 0
    else
        exit 1
    fi
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [CONFIG_ROOT] [BACKUP_DIR]"
        echo ""
        echo "Tests that a restructured NixOS configuration builds and functions correctly."
        echo ""
        echo "Arguments:"
        echo "  CONFIG_ROOT    Path to new NixOS configuration root (default: parent of script directory)"
        echo "  BACKUP_DIR     Path to backup of original configuration (auto-detected if not provided)"
        echo ""
        echo "Options:"
        echo "  --help, -h     Show this help message"
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac