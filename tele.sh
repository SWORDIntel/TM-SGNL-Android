#!/usr/bin/env bash
# TeleMessage Component Removal Script
# This script identifies and removes all TeleMessage-related components from the TM-SGNL-Android codebase.
# Security features: logging, error handling, backup creation, and audit trails.

set -e

# ANSI color codes for better visibility
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT=$(pwd)
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="${PROJECT_ROOT}/backup_telemessage_${TIMESTAMP}"
LOG_FILE="${PROJECT_ROOT}/telemessage_removal_${TIMESTAMP}.log"
AUDIT_FILE="${PROJECT_ROOT}/telemessage_audit_${TIMESTAMP}.csv"

# Progress tracking
TOTAL_STEPS=7
CURRENT_STEP=0

# Initialize log and audit files with headers
echo "TeleMessage Component Removal Log - ${TIMESTAMP}" > "$LOG_FILE"
echo "timestamp,action,component,path,status,details" > "$AUDIT_FILE"

# Logging function with audit trail
log() {
    local level=$1
    local message=$2
    local component=$3
    local path=$4
    local status=$5
    local details=$6
    
    # Log to console
    if [[ "$level" == "INFO" ]]; then
        echo -e "${GREEN}[INFO]${NC} $message"
    elif [[ "$level" == "WARN" ]]; then
        echo -e "${YELLOW}[WARN]${NC} $message"
    elif [[ "$level" == "ERROR" ]]; then
        echo -e "${RED}[ERROR]${NC} $message"
    elif [[ "$level" == "STEP" ]]; then
        CURRENT_STEP=$((CURRENT_STEP + 1))
        echo -e "\n${BLUE}[STEP $CURRENT_STEP/$TOTAL_STEPS]${NC} $message"
    fi
    
    # Log to file
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] [$level] $message" >> "$LOG_FILE"
    
    # Add to audit trail if component is specified
    if [[ -n "$component" ]]; then
        echo "$(date +"%Y-%m-%d %H:%M:%S"),$level,$component,\"$path\",\"$status\",\"$details\"" >> "$AUDIT_FILE"
    fi
}

# Error handling function
handle_error() {
    log "ERROR" "An error occurred at line $1. Check the log file for details."
    log "INFO" "A backup of files was created at $BACKUP_DIR"
    exit 1
}

# Set up error handling
trap 'handle_error $LINENO' ERR

# Function to create a backup of files before modification
create_backup() {
    log "STEP" "Creating backup of TeleMessage components..."
    
    mkdir -p "$BACKUP_DIR"
    
    # Backup AAR files
    log "INFO" "Backing up AAR files from app/libs/"
    mkdir -p "${BACKUP_DIR}/app/libs"
    find "${PROJECT_ROOT}/app/libs" -name "*signal*.aar" -o -name "common*.aar" -exec cp {} "${BACKUP_DIR}/app/libs/" \; 2>/dev/null || true
    
    # Backup source code
    log "INFO" "Backing up TeleMessage-related source code"
    if [ -d "${PROJECT_ROOT}/app/src/tm/java/org/archiver" ]; then
        mkdir -p "${BACKUP_DIR}/app/src/tm/java/org/archiver"
        cp -r "${PROJECT_ROOT}/app/src/tm/java/org/archiver" "${BACKUP_DIR}/app/src/tm/java/" 2>/dev/null || true
    fi
    
    # Backup build files
    log "INFO" "Backing up build files"
    cp "${PROJECT_ROOT}/app/build.gradle.kts" "${BACKUP_DIR}/app_build.gradle.kts.bak" 2>/dev/null || true
    cp "${PROJECT_ROOT}/build.gradle.kts" "${BACKUP_DIR}/build.gradle.kts.bak" 2>/dev/null || true
    
    log "INFO" "Backup completed at $BACKUP_DIR"
}

# Function to remove AAR files
remove_aar_files() {
    log "STEP" "Removing TeleMessage AAR files..."
    
    local aar_count=0
    local removed_count=0
    
    # Find and count AAR files
    while IFS= read -r file; do
        aar_count=$((aar_count + 1))
        log "INFO" "Found AAR file: $file" "AAR" "$file" "FOUND" ""
    done < <(find "${PROJECT_ROOT}/app/libs" -name "androidcopysdk-signal*.aar" -o -name "authenticatorsdk-signal*.aar" -o -name "common*.aar" 2>/dev/null || true)
    
    # Remove AAR files
    while IFS= read -r file; do
        rm -f "$file"
        removed_count=$((removed_count + 1))
        log "INFO" "Removed AAR file: $file" "AAR" "$file" "REMOVED" ""
    done < <(find "${PROJECT_ROOT}/app/libs" -name "androidcopysdk-signal*.aar" -o -name "authenticatorsdk-signal*.aar" -o -name "common*.aar" 2>/dev/null || true)
    
    log "INFO" "Removed $removed_count TeleMessage AAR files out of $aar_count found"
}

# Function to update build files
update_build_files() {
    log "STEP" "Updating build files to remove TeleMessage dependencies..."
    
    local build_files=(
        "${PROJECT_ROOT}/app/build.gradle.kts"
        "${PROJECT_ROOT}/build.gradle.kts"
        "${PROJECT_ROOT}/settings.gradle.kts"
    )
    
    for build_file in "${build_files[@]}"; do
        if [ -f "$build_file" ]; then
            log "INFO" "Checking build file: $build_file" "BUILD" "$build_file" "CHECKING" ""
            
            # Create a temporary file
            local temp_file="${build_file}.tmp"
            
            # Remove implementation lines for TeleMessage AAR files
            if grep -q "implementation(fileTree" "$build_file" || grep -q "implementation.*androidcopysdk-signal" "$build_file" || grep -q "implementation.*authenticatorsdk-signal" "$build_file" || grep -q "implementation.*common" "$build_file"; then
                grep -v "implementation.*androidcopysdk-signal" "$build_file" | grep -v "implementation.*authenticatorsdk-signal" | grep -v "implementation.*common" > "$temp_file"
                mv "$temp_file" "$build_file"
                log "INFO" "Removed TeleMessage dependencies from $build_file" "BUILD" "$build_file" "UPDATED" "Removed TeleMessage dependencies"
            else
                log "INFO" "No TeleMessage dependencies found in $build_file" "BUILD" "$build_file" "UNCHANGED" "No dependencies found"
            fi
        fi
    done
}

# Function to remove TeleMessage source code
remove_source_code() {
    log "STEP" "Removing TeleMessage source code..."
    
    # Remove archiver directory if it exists
    if [ -d "${PROJECT_ROOT}/app/src/tm/java/org/archiver" ]; then
        rm -rf "${PROJECT_ROOT}/app/src/tm/java/org/archiver"
        log "INFO" "Removed archiver directory" "SOURCE" "app/src/tm/java/org/archiver" "REMOVED" "Entire directory"
    else
        log "INFO" "Archiver directory not found" "SOURCE" "app/src/tm/java/org/archiver" "NOT_FOUND" ""
    fi
    
    # Find and remove other TeleMessage-related source files
    log "INFO" "Searching for TeleMessage-related source files..."
    
    find "${PROJECT_ROOT}/app/src" -type f -name "*.java" -o -name "*.kt" | xargs grep -l "TeleMessage\|telemessage\|archiveSender\|ArchiveSender\|ArchiveUtil\|ArchiveConstants" 2>/dev/null | while read -r file; do
        log "INFO" "Found TeleMessage reference in: $file" "SOURCE" "$file" "FOUND" ""
        
        # Determine if the file should be removed or modified
        if grep -q "package.*archiver" "$file" || grep -q "import.*archiver" "$file"; then
            # This file is part of the archiver package or heavily dependent on it - remove it
            rm -f "$file"
            log "INFO" "Removed file: $file" "SOURCE" "$file" "REMOVED" "Archiver-specific file"
        else
            # This file just has some references - remove those lines
            local temp_file="${file}.tmp"
            grep -v "import.*archiver\|TeleMessage\|telemessage\|ArchiveSender\|ArchiveUtil\|ArchiveConstants" "$file" > "$temp_file"
            mv "$temp_file" "$file"
            log "INFO" "Removed TeleMessage references from: $file" "SOURCE" "$file" "MODIFIED" "Removed references"
        fi
    done
}

# Function to remove TeleMessage configurations
remove_configurations() {
    log "STEP" "Removing TeleMessage configuration files and constants..."
    
    # Find and remove any TeleMessage-specific configuration files
    find "${PROJECT_ROOT}" -name "*telemessage*.json" -o -name "*telemessage*.xml" -o -name "*archive*config*.json" -o -name "*archive*config*.xml" | while read -r config_file; do
        rm -f "$config_file"
        log "INFO" "Removed configuration file: $config_file" "CONFIG" "$config_file" "REMOVED" ""
    done
    
    # Find ArchiveConstants.kt and remove it or modify it
    local constants_file=$(find "${PROJECT_ROOT}" -name "ArchiveConstants.kt" 2>/dev/null || true)
    if [ -n "$constants_file" ]; then
        rm -f "$constants_file"
        log "INFO" "Removed ArchiveConstants.kt: $constants_file" "CONFIG" "$constants_file" "REMOVED" ""
    fi
}

# Function to clean UI/UX references
clean_ui_references() {
    log "STEP" "Cleaning UI/UX references to TeleMessage..."
    
    # Find and clean string resources
    find "${PROJECT_ROOT}/app/src" -name "strings.xml" | while read -r strings_file; do
        local temp_file="${strings_file}.tmp"
        grep -v "TeleMessage\|telemessage\|archiv" "$strings_file" > "$temp_file"
        mv "$temp_file" "$strings_file"
        log "INFO" "Cleaned strings file: $strings_file" "UI" "$strings_file" "MODIFIED" "Removed TeleMessage strings"
    done
    
    # Find and clean layout files with TeleMessage references
    find "${PROJECT_ROOT}/app/src" -name "*.xml" -path "*/layout/*" | xargs grep -l "TeleMessage\|telemessage\|archiv" 2>/dev/null | while read -r layout_file; do
        local temp_file="${layout_file}.tmp"
        grep -v "TeleMessage\|telemessage\|archiv" "$layout_file" > "$temp_file"
        mv "$temp_file" "$layout_file"
        log "INFO" "Cleaned layout file: $layout_file" "UI" "$layout_file" "MODIFIED" "Removed TeleMessage references"
    done
}

# Function to perform final security audit
perform_security_audit() {
    log "STEP" "Performing final security audit..."
    
    # Search for any remaining TeleMessage references
    log "INFO" "Searching for any remaining TeleMessage references..."
    
    local remaining_refs=0
    
    # Find in code files
    while IFS= read -r file; do
        remaining_refs=$((remaining_refs + 1))
        log "WARN" "Remaining TeleMessage reference in: $file" "AUDIT" "$file" "FOUND" "Remaining reference found"
    done < <(find "${PROJECT_ROOT}" -type f \( -name "*.java" -o -name "*.kt" -o -name "*.xml" -o -name "*.gradle" -o -name "*.kts" \) -exec grep -l "TeleMessage\|telemessage\|archiveSender\|ArchiveSender\|ArchiveUtil\|ArchiveConstants\|androidcopysdk\|authenticatorsdk" {} \; 2>/dev/null || true)
    
    # Find any remaining AAR files
    while IFS= read -r file; do
        remaining_refs=$((remaining_refs + 1))
        log "WARN" "Remaining TeleMessage AAR file: $file" "AUDIT" "$file" "FOUND" "AAR file not removed"
    done < <(find "${PROJECT_ROOT}" -name "androidcopysdk-signal*.aar" -o -name "authenticatorsdk-signal*.aar" -o -name "common*.aar" 2>/dev/null || true)
    
    if [ $remaining_refs -eq 0 ]; then
        log "INFO" "Security audit passed: No remaining TeleMessage references found" "AUDIT" "all" "PASSED" "Clean codebase"
    else
        log "WARN" "Security audit warning: Found $remaining_refs remaining TeleMessage references" "AUDIT" "all" "WARNING" "$remaining_refs references found"
    fi
}

# Main execution
main() {
    log "INFO" "Starting TeleMessage component removal process..."
    
    # Perform steps in sequence
    create_backup
    remove_aar_files
    update_build_files
    remove_source_code
    remove_configurations
    clean_ui_references
    perform_security_audit
    
    log "INFO" "TeleMessage component removal completed successfully!"
    log "INFO" "Log file: $LOG_FILE"
    log "INFO" "Audit file: $AUDIT_FILE"
    log "INFO" "Backup directory: $BACKUP_DIR"
}

# Execute main function
main

exit 0
