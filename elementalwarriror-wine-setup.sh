#!/bin/bash

# Set strict mode
set -euo pipefail

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to check dependencies
check_dependencies() {
    local deps=("wget" "curl" "unzip" "jq" "git")
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

    # Create a temporary directory for extraction
    create_directory "$temp_dir"

    # Unzip the file to the temporary directory
    sudo unzip "$wine_zip_path" -d "$temp_dir"

    # Move the contents of the extracted directory to the target directory
    sudo mv "$temp_dir/ElementalWarriorWine/"* "$target_dir/"

    # Clean up the temporary directory
    sudo rm -rf "$temp_dir"

    # Remove the original ZIP file after extraction
    sudo rm -f "$wine_zip_path"

    # Create wine64 symlink
    log "Creating wine64 symlink..."
    sudo ln -sf "$target_dir/bin/wine" "$target_dir/bin/wine64"

    # Create wineprefix directory
    create_directory "$wineprefix"

    # Ensure correct ownership of wineprefix directory
    sudo chown -R "$USER:$USER" "$wineprefix"

    # Initialize wineprefix using rum
    log "Initializing wineprefix..."
    rum "$wine_build_name" "$wineprefix" wineboot --init

    # Wait for wineserver to finish
    sleep 5  # Give wineserver some time to complete initialization

    # Download WinMetadata
    log "Downloading WinMetadata..."
    download_file "https://archive.org/download/win-metadata/WinMetadata.zip" \
                  "$wineprefix/WinMetadata.zip" \
                  "WinMetadata"

    # Install dependencies with winetricks
    log "Installing dependencies with winetricks..."
    rum "$wine_build_name" "$wineprefix" winetricks -q -f dotnet48 corefonts
    rum "$wine_build_name" "$wineprefix" winetricks renderer=vulkan

    # Set Windows version to 11
    log "Setting Windows version to 11..."
    rum "$wine_build_name" "$wineprefix" wine winecfg -v win11

    # Extract WinMetadata files
    log "Extracting WinMetadata files..."
    create_directory "$wineprefix/drive_c/windows/system32/WinMetadata"
    unzip -q "$wineprefix/WinMetadata.zip" -d "$wineprefix/drive_c/windows/system32/WinMetadata"
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
