#!/usr/bin/env bash

# NixOS Configuration Migration Verification System
# Compares original and restructured configurations for functional equivalence
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

# Global counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

log_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

log_error() {
    echo -e "${RED}✗ $1${NC}" >&2
    ((FAILED_CHECKS++))
}

log_success() {
    echo -e "${GREEN}✓ $1${NC}"
    ((PASSED_CHECKS++))
}

log_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

log_info() {
    echo "INFO: $1"
}

increment_check() {
    ((TOTAL_CHECKS++))
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

# Extract package lists from configuration
extract_packages() {
    local config_file="$1"
    local output_file="$2"
    
    if [[ ! -f "$config_file" ]]; then
        echo "Configuration file not found: $config_file" > "$output_file"
        return 1
    fi
    
    # Extract packages from various sources in the configuration
    {
        # System packages
        grep -E "^\s*environment\.systemPackages.*with.*pkgs" "$config_file" 2>/dev/null || true
        grep -E "^\s*pkgs\." "$config_file" 2>/dev/null || true
        
        # Look for package imports
        grep -E "^\s*\./.*packages" "$config_file" 2>/dev/null || true
        
        # Look for specific package declarations
        grep -E "^\s*programs\." "$config_file" 2>/dev/null || true
        grep -E "^\s*services\." "$config_file" 2>/dev/null || true
    } | sort | uniq > "$output_file"
}

# Extract services from configuration
extract_services() {
    local config_file="$1"
    local output_file="$2"
    
    if [[ ! -f "$config_file" ]]; then
        echo "Configuration file not found: $config_file" > "$output_file"
        return 1
    fi
    
    # Extract service configurations
    {
        grep -E "^\s*services\." "$config_file" 2>/dev/null || true
        grep -E "^\s*systemd\.services\." "$config_file" 2>/dev/null || true
        grep -E "enable\s*=\s*true" "$config_file" 2>/dev/null || true
    } | sort | uniq > "$output_file"
}

# Extract user configurations
extract_users() {
    local config_file="$1"
    local output_file="$2"
    
    if [[ ! -f "$config_file" ]]; then
        echo "Configuration file not found: $config_file" > "$output_file"
        return 1
    fi
    
    # Extract user-related configurations
    {
        grep -E "^\s*users\.users\." "$config_file" 2>/dev/null || true
        grep -E "^\s*home-manager\.users\." "$config_file" 2>/dev/null || true
        grep -E "^\s*users\.extraUsers\." "$config_file" 2>/dev/null || true
    } | sort | uniq > "$output_file"
}

# Compare two files and report differences
compare_files() {
    local file1="$1"
    local file2="$2"
    local description="$3"
    
    increment_check
    
    if [[ ! -f "$file1" ]]; then
        log_error "$description: Original file missing ($file1)"
        return 1
    fi
    
    if [[ ! -f "$file2" ]]; then
        log_error "$description: New file missing ($file2)"
        return 1
    fi
    
    if diff -q "$file1" "$file2" >/dev/null 2>&1; then
        log_success "$description: Configurations match"
        return 0
    else
        log_warning "$description: Configurations differ"
        echo "Differences found:"
        diff -u "$file1" "$file2" | head -20
        echo ""
        return 1
    fi
}

# Compare package configurations
compare_packages() {
    log_header "Comparing Package Configurations"
    
    local temp_dir=$(mktemp -d)
    local original_packages="$temp_dir/original_packages.txt"
    local new_packages="$temp_dir/new_packages.txt"
    
    # Extract packages from original configuration
    if [[ -f "$BACKUP_DIR/configuration.nix" ]]; then
        extract_packages "$BACKUP_DIR/configuration.nix" "$original_packages"
    elif [[ -f "$BACKUP_DIR/packages.nix" ]]; then
        extract_packages "$BACKUP_DIR/packages.nix" "$original_packages"
    else
        log_error "Could not find original package configuration"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Extract packages from new configuration
    local new_config_files=(
        "$CONFIG_ROOT/modules/system/packages.nix"
        "$CONFIG_ROOT/modules/development/default.nix"
        "$CONFIG_ROOT/profiles/desktop.nix"
    )
    
    > "$new_packages"
    for config_file in "${new_config_files[@]}"; do
        if [[ -f "$config_file" ]]; then
            extract_packages "$config_file" "$temp_dir/temp_packages.txt"
            cat "$temp_dir/temp_packages.txt" >> "$new_packages"
        fi
    done
    
    sort "$new_packages" | uniq > "$temp_dir/new_packages_sorted.txt"
    mv "$temp_dir/new_packages_sorted.txt" "$new_packages"
    
    compare_files "$original_packages" "$new_packages" "Package configurations"
    
    rm -rf "$temp_dir"
}

# Compare service configurations
compare_services() {
    log_header "Comparing Service Configurations"
    
    local temp_dir=$(mktemp -d)
    local original_services="$temp_dir/original_services.txt"
    local new_services="$temp_dir/new_services.txt"
    
    # Extract services from original configuration
    if [[ -f "$BACKUP_DIR/configuration.nix" ]]; then
        extract_services "$BACKUP_DIR/configuration.nix" "$original_services"
    else
        log_error "Could not find original service configuration"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Extract services from new configuration
    local new_config_files=(
        "$CONFIG_ROOT/hosts/thonkpad/configuration.nix"
        "$CONFIG_ROOT/modules/services/default.nix"
        "$CONFIG_ROOT/modules/services/docker.nix"
        "$CONFIG_ROOT/modules/services/openssh.nix"
    )
    
    > "$new_services"
    for config_file in "${new_config_files[@]}"; do
        if [[ -f "$config_file" ]]; then
            extract_services "$config_file" "$temp_dir/temp_services.txt"
            cat "$temp_dir/temp_services.txt" >> "$new_services"
        fi
    done
    
    sort "$new_services" | uniq > "$temp_dir/new_services_sorted.txt"
    mv "$temp_dir/new_services_sorted.txt" "$new_services"
    
    compare_files "$original_services" "$new_services" "Service configurations"
    
    rm -rf "$temp_dir"
}

# Compare user configurations
compare_users() {
    log_header "Comparing User Configurations"
    
    local temp_dir=$(mktemp -d)
    local original_users="$temp_dir/original_users.txt"
    local new_users="$temp_dir/new_users.txt"
    
    # Extract users from original configuration
    local original_files=(
        "$BACKUP_DIR/configuration.nix"
        "$BACKUP_DIR/main-user.nix"
        "$BACKUP_DIR/home.nix"
    )
    
    > "$original_users"
    for config_file in "${original_files[@]}"; do
        if [[ -f "$config_file" ]]; then
            extract_users "$config_file" "$temp_dir/temp_users.txt"
            cat "$temp_dir/temp_users.txt" >> "$original_users"
        fi
    done
    
    sort "$original_users" | uniq > "$temp_dir/original_users_sorted.txt"
    mv "$temp_dir/original_users_sorted.txt" "$original_users"
    
    # Extract users from new configuration
    local new_config_files=(
        "$CONFIG_ROOT/hosts/thonkpad/users.nix"
        "$CONFIG_ROOT/users/jacob/default.nix"
        "$CONFIG_ROOT/users/jacob/home.nix"
        "$CONFIG_ROOT/users/jacob/system.nix"
    )
    
    > "$new_users"
    for config_file in "${new_config_files[@]}"; do
        if [[ -f "$config_file" ]]; then
            extract_users "$config_file" "$temp_dir/temp_users.txt"
            cat "$temp_dir/temp_users.txt" >> "$new_users"
        fi
    done
    
    sort "$new_users" | uniq > "$temp_dir/new_users_sorted.txt"
    mv "$temp_dir/new_users_sorted.txt" "$new_users"
    
    compare_files "$original_users" "$new_users" "User configurations"
    
    rm -rf "$temp_dir"
}

# Test that configurations can be built
test_build_compatibility() {
    log_header "Testing Build Compatibility"
    
    increment_check
    
    # Test that the new configuration can be evaluated
    if [[ -f "$CONFIG_ROOT/flake.nix" ]]; then
        log_info "Testing flake evaluation..."
        
        if nix flake check "$CONFIG_ROOT" --no-build 2>/dev/null; then
            log_success "New configuration builds successfully"
        else
            log_error "New configuration fails to build"
            return 1
        fi
    else
        log_error "No flake.nix found in new configuration"
        return 1
    fi
    
    # Test that we can show the configuration outputs
    increment_check
    if nix flake show "$CONFIG_ROOT" &>/dev/null; then
        log_success "Configuration outputs are valid"
    else
        log_error "Configuration outputs are invalid"
        return 1
    fi
}

# Generate comprehensive migration report
generate_migration_report() {
    log_header "Migration Verification Report"
    
    echo "Configuration Root: $CONFIG_ROOT"
    echo "Backup Directory: $BACKUP_DIR"
    echo "Verification Date: $(date)"
    echo ""
    
    # Run all comparisons
    compare_packages
    echo ""
    compare_services  
    echo ""
    compare_users
    echo ""
    test_build_compatibility
    echo ""
    
    # Summary
    log_header "Verification Summary"
    echo "Total Checks: $TOTAL_CHECKS"
    echo "Passed: $PASSED_CHECKS"
    echo "Failed: $FAILED_CHECKS"
    echo ""
    
    local success_rate=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))
    echo "Success Rate: $success_rate%"
    
    if [[ $FAILED_CHECKS -eq 0 ]]; then
        log_success "Migration verification completed successfully!"
        echo "The restructured configuration appears to be functionally equivalent to the original."
        return 0
    else
        log_error "Migration verification found issues"
        echo "Please review the differences above and ensure they are intentional."
        return 1
    fi
}

# Main function
main() {
    echo "NixOS Configuration Migration Verification"
    echo "========================================"
    echo ""
    
    # Find backup directory
    if ! BACKUP_DIR=$(find_backup_dir); then
        log_error "Could not find backup directory. Please specify it as the second argument."
        echo "Usage: $0 [CONFIG_ROOT] [BACKUP_DIR]"
        exit 1
    fi
    
    log_info "Using backup directory: $BACKUP_DIR"
    echo ""
    
    # Check prerequisites
    if ! command -v nix &> /dev/null; then
        log_error "Nix is required but not found in PATH"
        exit 1
    fi
    
    if ! command -v diff &> /dev/null; then
        log_error "diff command is required but not found in PATH"
        exit 1
    fi
    
    # Run verification
    if generate_migration_report; then
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
        echo "Verifies that a restructured NixOS configuration is functionally equivalent"
        echo "to the original configuration."
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