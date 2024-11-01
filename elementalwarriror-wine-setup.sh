#!/bin/bash

# Set strict mode
set -euo pipefail

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to check dependencies
check_dependencies() {
    local deps=("wget" "curl" "7z" "jq" "git" "winetricks")
    local missing_deps=()

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done

    if [ ${#missing_deps[@]} -ne 0 ]; then
        log "ERROR: Missing dependencies: ${missing_deps[*]}"
        log "Please install them and rerun the script."
        exit 1
    fi
    log "All dependencies are installed!"
}

# Function to install rum
install_rum() {
    log "Installing rum..."

    if ! command -v rum &> /dev/null; then
        # Clone rum repository
        if [ ! -d "$HOME/Documents/rum" ]; then
            git clone https://gitlab.com/xkero/rum "$HOME/Documents/rum"
        else
            log "rum repository already exists, skipping clone..."
        fi

        # Copy rum to /usr/local/bin
        if [ ! -f "/usr/local/bin/rum" ]; then
            sudo cp "$HOME/Documents/rum/rum" "/usr/local/bin/rum"
            sudo chmod +x "/usr/local/bin/rum"
            log "rum installed successfully!"
        else
            log "rum already installed in /usr/local/bin, skipping..."
        fi
    else
        log "rum is already installed, skipping..."
        return 0
    fi
}

# Function to safely create directory
create_directory() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        sudo mkdir -p "$dir" || { log "ERROR: Failed to create directory $dir"; exit 1; }
    fi
}

# Function to download file with verification
download_file() {
    local url="$1"
    local output="$2"
    local description="$3"

    log "Downloading $description..."
    if ! curl -L -s "$url" -o "$output"; then
        log "ERROR: Failed to download $description"
        return 1
    fi
    log "Successfully downloaded $description"
    return 0
}

# Main script execution
main() {
    # Configuration
    local wine_build_name="affinity-photo3-wine9.13-part3"
    local wines_dir="/opt/wines"
    local wineprefix="$HOME/.wineAffinity"
    local repo="22-pacific/ElementalWarrior-wine-binaries"
    local filename="ElementalWarriorWine.zip"

    # Check dependencies
    check_dependencies

    # Install rum
    install_rum

    # Create wines directory and set permissions
    log "Creating wines directory..."
    create_directory "$wines_dir"
    sudo chown "$USER:$USER" "$wines_dir"

    # Fetch latest release information
    log "Fetching release information..."
    local release_info
    release_info=$(curl -s "https://api.github.com/repos/$repo/releases/latest") || { log "ERROR: Failed to fetch release info"; exit 1; }
    local download_url
    download_url=$(echo "$release_info" | jq -r ".assets[] | select(.name == \"$filename\") | .browser_download_url")

    if [ -z "$download_url" ]; then
        log "ERROR: File not found in the latest release"
        exit 1
    fi

    # Download and verify wine binaries
    download_file "$download_url" "$wines_dir/$filename" "wine binaries"

    # Define the paths
    local wine_zip_path="$wines_dir/$filename"
    local temp_dir="$wines_dir/temp"
    local target_dir="$wines_dir/$wine_build_name"

    # Create the target directory if it doesn't exist
    create_directory "$target_dir"

    # Extract directly to target directory
    log "Extracting wine binaries..."
    sudo 7z x "$wine_zip_path" -o"$target_dir" -y

    # Move files from subdirectory to target directory
    log "Moving files to correct location..."
    sudo mv "$target_dir/ElementalWarriorWine"/* "$target_dir/"
    sudo rmdir "$target_dir/ElementalWarriorWine"

    # Create wine64 symlink
    log "Creating wine64 symlink..."
    if ! sudo ln -sf "$target_dir/bin/wine" "$target_dir/bin/wine64"; then
        log "ERROR: Failed to create wine64 symlink"
        exit 1
    fi

    # Create wineprefix directory
    mkdir -p "$wineprefix"  # Simple mkdir is sufficient for home directory

    # Initialize wineprefix using rum
    log "Initializing wineprefix..."
    rum "$wine_build_name" "$wineprefix" wineboot --init

    # Wait for wineserver to finish
    log "Waiting for wineserver to finish..."
    wineserver -w

    # Download WinMetadata with error handling
    log "Downloading WinMetadata..."
    if ! download_file "https://archive.org/download/win-metadata/WinMetadata.zip" \
                      "$wineprefix/WinMetadata.zip" \
                      "WinMetadata"; then
        log "ERROR: Failed to download WinMetadata"
        exit 1
    fi

    # Install dependencies with winetricks (add error handling)
    log "Installing dependencies with winetricks..."
    if ! rum "$wine_build_name" "$wineprefix" winetricks -q -f dotnet48 corefonts; then
        log "ERROR: Failed to install winetricks dependencies"
        exit 1
    fi
    
    if ! rum "$wine_build_name" "$wineprefix" winetricks renderer=vulkan; then
        log "ERROR: Failed to set vulkan renderer"
        exit 1
    fi

    # Set Windows version to 11
    log "Setting Windows version to 11..."
    rum "$wine_build_name" "$wineprefix" wine winecfg -v win11

    # Extract WinMetadata files
    log "Extracting WinMetadata files..."
    mkdir -p "$wineprefix/drive_c/windows/system32/WinMetadata"
    7z x "$wineprefix/WinMetadata.zip" -o"$wineprefix/drive_c/windows/system32/WinMetadata" -y
    
    # Move files from subdirectory to correct location
    mv "$wineprefix/drive_c/windows/system32/WinMetadata/WinMetadata"/* \
       "$wineprefix/drive_c/windows/system32/WinMetadata/"
    rmdir "$wineprefix/drive_c/windows/system32/WinMetadata/WinMetadata"
    
    rm "$wineprefix/WinMetadata.zip"

    log "Setup completed successfully!"
    log "Wine build location: $wines_dir/$wine_build_name"
    log "Wineprefix location: $wineprefix"
}

# Check if script is run as root
if [ "$EUID" -eq 0 ]; then
    log "ERROR: This script should not be run as root"
    exit 1
fi

# Run main function
main "$@"
