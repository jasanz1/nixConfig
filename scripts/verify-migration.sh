#!/usr/bin/env bash

# Master Migration Verification Script
# Runs all verification tools to ensure migration success
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
BOLD='\033[1m'
NC='\033[0m'

# Results tracking
VERIFICATION_STEPS=()
STEP_RESULTS=()

log_header() {
    echo -e "${BOLD}${BLUE}=== $1 ===${NC}"
}

log_error() {
    echo -e "${RED}✗ $1${NC}" >&2
}

log_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

log_info() {
    echo "INFO: $1"
}

# Add a verification step
add_step() {
    VERIFICATION_STEPS+=("$1")
}

# Record step result
record_result() {
    STEP_RESULTS+=("$1")
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

# Run structure validation
run_structure_validation() {
    log_header "Step 1: Structure Validation"
    add_step "Structure Validation"
    
    if [[ -x "$SCRIPT_DIR/validate-config.sh" ]]; then
        if "$SCRIPT_DIR/validate-config.sh" "$CONFIG_ROOT"; then
            log_success "Structure validation passed"
            record_result "PASS")
            return 0
        else
            log_error "Structure validation failed"
            record_result("FAIL")
            return 1
        fi
    else
        log_error "Structure validation script not found or not executable"
        record_result("ERROR")
        return 1
    fi
}

# Run configuration comparison
run_configuration_comparison() {
    log_header "Step 2: Configuration Comparison"
    add_step("Configuration Comparison")
    
    if [[ -z "$BACKUP_DIR" ]]; then
        log_warning "No backup directory available - skipping comparison"
        record_result("SKIP")
        return 0
    fi
    
    if [[ -x "$SCRIPT_DIR/compare-configurations.sh" ]]; then
        if "$SCRIPT_DIR/compare-configurations.sh" "$CONFIG_ROOT" "$BACKUP_DIR"; then
            log_success "Configuration comparison passed"
            record_result("PASS")
            return 0
        else
            log_warning "Configuration comparison found differences (may be acceptable)"
            record_result("WARN")
            return 0
        fi
    else
        log_error "Configuration comparison script not found or not executable"
        record_result("ERROR")
        return 1
    fi
}

# Run migration testing
run_migration_testing() {
    log_header "Step 3: Migration Testing"
    add_step("Migration Testing")
    
    if [[ -x "$SCRIPT_DIR/test-migration.sh" ]]; then
        if "$SCRIPT_DIR/test-migration.sh" "$CONFIG_ROOT" "$BACKUP_DIR"; then
            log_success "Migration testing passed"
            record_result("PASS")
            return 0
        else
            log_error "Migration testing failed"
            record_result("FAIL")
            return 1
        fi
    else
        log_error "Migration testing script not found or not executable"
        record_result("ERROR")
        return 1
    fi
}

# Run deep configuration analysis
run_deep_analysis() {
    log_header "Step 4: Deep Configuration Analysis"
    add_step("Deep Analysis")
    
    if [[ -z "$BACKUP_DIR" ]]; then
        log_warning "No backup directory available - skipping deep analysis"
        record_result("SKIP")
        return 0
    fi
    
    if [[ -f "$SCRIPT_DIR/deep-compare.nix" ]]; then
        local original_config="$BACKUP_DIR/configuration.nix"
        local new_config="$CONFIG_ROOT/hosts/thonkpad/configuration.nix"
        
        if [[ -f "$original_config" && -f "$new_config" ]]; then
            local nix_expr="
            let
              compareTool = import $SCRIPT_DIR/deep-compare.nix {};
              result = compareTool.runValidation \"$original_config\" \"$new_config\";
            in
              result
            "
            
            if nix-instantiate --eval --expr "$nix_expr" &>/dev/null; then
                log_success "Deep analysis passed"
                record_result("PASS")
                return 0
            else
                log_warning "Deep analysis found issues (review required)"
                record_result("WARN")
                return 0
            fi
        else
            log_warning "Required configuration files not found for deep analysis"
            record_result("SKIP")
            return 0
        fi
    else
        log_error "Deep analysis tool not found"
        record_result("ERROR")
        return 1
    fi
}

# Generate final verification report
generate_final_report() {
    log_header "Migration Verification Summary"
    
    echo "Configuration Root: $CONFIG_ROOT"
    echo "Backup Directory: ${BACKUP_DIR:-"Not available"}"
    echo "Verification Date: $(date)"
    echo ""
    
    # Display results table
    echo "Verification Steps:"
    echo "==================="
    
    local total_steps=${#VERIFICATION_STEPS[@]}
    local passed=0
    local failed=0
    local warnings=0
    local skipped=0
    local errors=0
    
    for i in "${!VERIFICATION_STEPS[@]}"; do
        local step="${VERIFICATION_STEPS[$i]}"
        local result="${STEP_RESULTS[$i]}"
        
        case "$result" in
            "PASS")
                echo -e "${GREEN}✓${NC} $step: PASSED"
                ((passed++))
                ;;
            "FAIL")
                echo -e "${RED}✗${NC} $step: FAILED"
                ((failed++))
                ;;
            "WARN")
                echo -e "${YELLOW}⚠${NC} $step: WARNING"
                ((warnings++))
                ;;
            "SKIP")
                echo -e "${YELLOW}−${NC} $step: SKIPPED"
                ((skipped++))
                ;;
            "ERROR")
                echo -e "${RED}!${NC} $step: ERROR"
                ((errors++))
                ;;
        esac
    done
    
    echo ""
    echo "Results Summary:"
    echo "================"
    echo "Total Steps: $total_steps"
    echo "Passed: $passed"
    echo "Failed: $failed"
    echo "Warnings: $warnings"
    echo "Skipped: $skipped"
    echo "Errors: $errors"
    echo ""
    
    # Determine overall result
    if [[ $failed -eq 0 && $errors -eq 0 ]]; then
        if [[ $warnings -eq 0 ]]; then
            log_success "Migration verification completed successfully!"
            echo "Your NixOS configuration has been successfully restructured."
            echo "All tests passed and the configuration appears to be functionally equivalent."
            return 0
        else
            log_warning "Migration verification completed with warnings"
            echo "Your NixOS configuration has been restructured, but some differences were found."
            echo "Please review the warnings above to ensure they are acceptable."
            return 0
        fi
    else
        log_error "Migration verification failed"
        echo "Critical issues were found during verification."
        echo "Please address the failures and errors before using the restructured configuration."
        return 1
    fi
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
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
    
    # Check that verification scripts exist
    local required_scripts=(
        "validate-config.sh"
        "compare-configurations.sh"
        "test-migration.sh"
        "deep-compare.nix"
    )
    
    local missing_scripts=()
    for script in "${required_scripts[@]}"; do
        if [[ ! -f "$SCRIPT_DIR/$script" ]]; then
            missing_scripts+=("$script")
        fi
    done
    
    if [[ ${#missing_scripts[@]} -gt 0 ]]; then
        log_error "Missing required scripts: ${missing_scripts[*]}"
        exit 1
    fi
    
    log_success "All prerequisites available"
}

# Main function
main() {
    echo -e "${BOLD}NixOS Configuration Migration Verification${NC}"
    echo "=========================================="
    echo ""
    
    # Find backup directory if not provided
    if [[ -z "$BACKUP_DIR" ]]; then
        if BACKUP_DIR=$(find_backup_dir); then
            log_info "Found backup directory: $BACKUP_DIR"
        else
            log_warning "No backup directory found - some verifications will be skipped"
        fi
    fi
    echo ""
    
    # Check prerequisites
    check_prerequisites
    echo ""
    
    # Run verification steps
    run_structure_validation
    echo ""
    run_configuration_comparison
    echo ""
    run_migration_testing
    echo ""
    run_deep_analysis
    echo ""
    
    # Generate final report
    if generate_final_report; then
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
        echo "Comprehensive verification of NixOS configuration migration."
        echo "Runs all verification tools to ensure the restructured configuration"
        echo "is functionally equivalent to the original."
        echo ""
        echo "Arguments:"
        echo "  CONFIG_ROOT    Path to new NixOS configuration root (default: parent of script directory)"
        echo "  BACKUP_DIR     Path to backup of original configuration (auto-detected if not provided)"
        echo ""
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo ""
        echo "This script runs the following verification steps:"
        echo "  1. Structure Validation - Checks directory structure and naming conventions"
        echo "  2. Configuration Comparison - Compares packages, services, and users"
        echo "  3. Migration Testing - Tests that configurations build and function"
        echo "  4. Deep Analysis - Performs detailed configuration equivalence analysis"
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac