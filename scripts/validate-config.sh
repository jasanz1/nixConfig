#!/usr/bin/env bash

# Comprehensive NixOS Configuration Validation
# This script runs all validation checks for the restructured NixOS configuration
# Requirements: 4.1, 4.2, 2.3

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_ROOT="${1:-$(dirname "$SCRIPT_DIR")}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

log_error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
}

log_success() {
    echo -e "${GREEN}SUCCESS: $1${NC}"
}

log_info() {
    echo "INFO: $1"
}

# Check if required tools are available
check_prerequisites() {
    log_header "Checking Prerequisites"
    
    local missing_tools=()
    
    if ! command -v nix &> /dev/null; then
        missing_tools+=("nix")
    fi
    
    if ! command -v bash &> /dev/null; then
        missing_tools+=("bash")
    fi
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        exit 1
    fi
    
    log_success "All prerequisites available"
}

# Run structure validation
run_structure_validation() {
    log_header "Running Structure Validation"
    
    if [[ -x "$SCRIPT_DIR/validate-structure.sh" ]]; then
        if "$SCRIPT_DIR/validate-structure.sh" "$CONFIG_ROOT"; then
            log_success "Structure validation passed"
            return 0
        else
            log_error "Structure validation failed"
            return 1
        fi
    else
        log_error "Structure validation script not found or not executable"
        return 1
    fi
}

# Run dependency validation using Nix
run_dependency_validation() {
    log_header "Running Dependency Validation"
    
    if [[ -f "$SCRIPT_DIR/validate-dependencies.nix" ]]; then
        local nix_expr="
        let
          validator = import $SCRIPT_DIR/validate-dependencies.nix {};
          result = validator.runValidation \"$CONFIG_ROOT\";
        in
          builtins.trace result result
        "
        
        if nix-instantiate --eval --expr "$nix_expr" &>/dev/null; then
            log_success "Dependency validation passed"
            return 0
        else
            log_error "Dependency validation failed"
            # Try to get more detailed output
            nix-instantiate --eval --expr "$nix_expr" 2>&1 || true
            return 1
        fi
    else
        log_error "Dependency validation script not found"
        return 1
    fi
}

# Test configuration building
test_configuration_build() {
    log_header "Testing Configuration Build"
    
    if [[ -f "$CONFIG_ROOT/flake.nix" ]]; then
        log_info "Testing flake evaluation..."
        
        # Test that the flake can be evaluated
        if nix flake check "$CONFIG_ROOT" --no-build 2>/dev/null; then
            log_success "Flake evaluation successful"
        else
            log_error "Flake evaluation failed"
            return 1
        fi
        
        # Test that we can show the flake outputs
        if nix flake show "$CONFIG_ROOT" &>/dev/null; then
            log_success "Flake outputs are valid"
        else
            log_error "Flake outputs are invalid"
            return 1
        fi
        
        return 0
    else
        log_error "No flake.nix found in $CONFIG_ROOT"
        return 1
    fi
}

# Validate specific configuration aspects
validate_configuration_aspects() {
    log_header "Validating Configuration Aspects"
    
    local validation_errors=0
    
    # Check that profiles exist and are valid
    if [[ -d "$CONFIG_ROOT/profiles" ]]; then
        for profile in "$CONFIG_ROOT/profiles"/*.nix; do
            if [[ -f "$profile" ]]; then
                local profile_name=$(basename "$profile" .nix)
                log_info "Validating profile: $profile_name"
                
                # Basic syntax check
                if nix-instantiate --parse "$profile" &>/dev/null; then
                    log_success "Profile $profile_name syntax is valid"
                else
                    log_error "Profile $profile_name has syntax errors"
                    ((validation_errors++))
                fi
            fi
        done
    else
        log_error "Profiles directory not found"
        ((validation_errors++))
    fi
    
    # Check that modules have proper structure
    if [[ -d "$CONFIG_ROOT/modules" ]]; then
        find "$CONFIG_ROOT/modules" -name "*.nix" -type f | while read -r module; do
            local module_name=$(basename "$module" .nix)
            log_info "Validating module: $module_name"
            
            # Basic syntax check
            if nix-instantiate --parse "$module" &>/dev/null; then
                log_success "Module $module_name syntax is valid"
            else
                log_error "Module $module_name has syntax errors"
                ((validation_errors++))
            fi
        done
    else
        log_error "Modules directory not found"
        ((validation_errors++))
    fi
    
    return $validation_errors
}

# Generate validation report
generate_report() {
    log_header "Validation Report"
    
    local total_checks=4
    local passed_checks=0
    
    echo "Configuration Root: $CONFIG_ROOT"
    echo "Validation Date: $(date)"
    echo ""
    
    # Structure validation
    if run_structure_validation; then
        echo "✓ Structure Validation: PASSED"
        ((passed_checks++))
    else
        echo "✗ Structure Validation: FAILED"
    fi
    
    # Dependency validation  
    if run_dependency_validation; then
        echo "✓ Dependency Validation: PASSED"
        ((passed_checks++))
    else
        echo "✗ Dependency Validation: FAILED"
    fi
    
    # Build test
    if test_configuration_build; then
        echo "✓ Configuration Build Test: PASSED"
        ((passed_checks++))
    else
        echo "✗ Configuration Build Test: FAILED"
    fi
    
    # Aspect validation
    if validate_configuration_aspects; then
        echo "✓ Configuration Aspects: PASSED"
        ((passed_checks++))
    else
        echo "✗ Configuration Aspects: FAILED"
    fi
    
    echo ""
    echo "Overall Result: $passed_checks/$total_checks checks passed"
    
    if [[ $passed_checks -eq $total_checks ]]; then
        log_success "All validation checks passed!"
        return 0
    else
        log_error "Some validation checks failed"
        return 1
    fi
}

# Main function
main() {
    echo "NixOS Configuration Validation Suite"
    echo "===================================="
    echo ""
    
    check_prerequisites
    echo ""
    
    if generate_report; then
        exit 0
    else
        exit 1
    fi
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [CONFIG_ROOT]"
        echo ""
        echo "Validates NixOS configuration structure and dependencies."
        echo ""
        echo "Arguments:"
        echo "  CONFIG_ROOT    Path to NixOS configuration root (default: parent of script directory)"
        echo ""
        echo "Options:"
        echo "  --help, -h     Show this help message"
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac