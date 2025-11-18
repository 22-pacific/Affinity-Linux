#!/usr/bin/env bash

# Affinity Plugin Loader Setup Script

set -e  # Exit on error
set -u  # Exit on undefined variable

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Main script
main() {
    log_info "Starting Affinity Plugin Loader setup..."

    # Define Wine prefix
    export WINEPREFIX="$HOME/.wineAffinity"
    log_info "Wine prefix set to: $WINEPREFIX"

    # Check if Wine prefix exists
    if [ ! -d "$WINEPREFIX" ]; then
        log_warning "Wine prefix does not exist: $WINEPREFIX"
        log_error "Please create the Wine prefix first or verify the path"
        exit 1
    fi

    # Define Affinity directory
    AFFINITY_DIR="$WINEPREFIX/drive_c/Program Files/Affinity/Affinity"
    log_info "Affinity directory: $AFFINITY_DIR"

    # Check if Affinity directory exists
    if [ ! -d "$AFFINITY_DIR" ]; then
        log_warning "Affinity directory does not exist: $AFFINITY_DIR"
        log_error "Please install Affinity first or verify the installation path"
        exit 1
    fi

    # Change to Affinity directory
    log_info "Changing to Affinity directory..."
    cd "$AFFINITY_DIR"
    log_success "Current directory: $(pwd)"

    # Download AffinityPluginLoader + WineFix bundle
    DOWNLOAD_URL="https://github.com/noahc3/AffinityPluginLoader/releases/latest/download/affinitypluginloader-plus-winefix.tar.xz"
    TEMP_FILE="/tmp/affinitypluginloader-plus-winefix.tar.xz"

    log_info "Downloading AffinityPluginLoader + WineFix bundle..."
    log_info "URL: $DOWNLOAD_URL"

    if curl -L -o "$TEMP_FILE" "$DOWNLOAD_URL"; then
        log_success "Download completed successfully"
    else
        log_error "Download failed"
        exit 1
    fi

    # Verify download
    if [ ! -f "$TEMP_FILE" ]; then
        log_error "Downloaded file not found: $TEMP_FILE"
        exit 1
    fi

    FILE_SIZE=$(du -h "$TEMP_FILE" | cut -f1)
    log_info "Downloaded file size: $FILE_SIZE"

    # Extract the archive
    log_info "Extracting archive to current directory..."
    if tar -xf "$TEMP_FILE" -C .; then
        log_success "Extraction completed successfully"
    else
        log_error "Extraction failed"
        exit 1
    fi

    # Clean up temporary file
    log_info "Cleaning up temporary files..."
    rm -f "$TEMP_FILE"
    log_success "Temporary file removed"

    # List extracted contents
    log_info "Listing extracted files:"
    ls -lah

    log_success "Setup completed successfully!"
    log_info "AffinityPluginLoader has been installed to: $AFFINITY_DIR"
}

# Run main function
main "$@"
