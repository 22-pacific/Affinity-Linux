#!/bin/bash
# Set strict mode
set -euo pipefail

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to install missing dependencies based on detected package manager
install_dependencies() {
    local deps=("wine" "wine-gecko" "wine-mono" "winetricks" "wget" "curl" "7z" "tar" "unzip" "jq")
    local missing_deps=()

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done

    if [ ${#missing_deps[@]} -ne 0 ]; then
        log "INFO: Missing dependencies: ${missing_deps[*]}"
    fi
    log "All dependencies are installed!"
}

# Function to safely create directory
create_directory() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir" || { log "ERROR: Failed to create directory $dir"; exit 1; }
    fi
}

# Function to download file with verification
download_file() {
    local url="$1"
    local output="$2"
    local description="$3"
    log "Downloading $description..."

    if [ -f "$output" ]; then
        log "$description already exists, skipping download."
        return 0
    fi

    if ! wget -q "$url" -O "$output"; then
        log "ERROR: Failed to download $description"
        return 1
    fi
    return 0
}

# Main script execution
main() {
    # Configuration
    local directory="$HOME/.AffinityLinux"
    local repo="22-pacific/ElementalWarrior-wine-binaries"
    local filename="ElementalWarriorWine.zip"
    local metadata_dir="$directory/drive_c/windows/system32"

    # Install/check dependencies
    install_dependencies

    # Kill wine processes
    wineserver -k || log "Note: No wine processes were running"

    # Create install directory
    create_directory "$directory"

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
    download_file "$download_url" "$directory/$filename" "wine binaries"

    # Verify file size
    local github_size
    github_size=$(echo "$release_info" | jq -r ".assets[] | select(.name == \"$filename\") | .size")
    local local_size
    local_size=$(wc -c < "$directory/$filename")

    if [ "$github_size" -ne "$local_size" ]; then
        log "WARNING: File size mismatch. Expected: $github_size, Got: $local_size"
        log "Please download $filename manually from $download_url"
        exit 1
    fi

    # Download WinMetadata
    download_file "https://archive.org/download/win-metadata/WinMetadata.zip" \
                  "$directory/Winmetadata.zip" \
                  "WinMetadata"

    # Extract files
    log "Extracting files..."
    unzip -q "$directory/$filename" -d "$directory"
    rm "$directory/$filename"

    # Set environment variables
    export WINE="$directory/ElementalWarriorWine/bin/wine"
    export WINESERVER="$directory/ElementalWarriorWine/bin/wineserver"
    export WINEARCH="win64"
    export WINEPREFIX="$directory"
    export PATH="$directory/ElementalWarriorWine/bin:$PATH"

    # Initialize Wine prefix
    log "Initializing Wine prefix..."
    "$directory/ElementalWarriorWine/bin/wineboot" --init

    # Wait for wineserver to finish
    "$directory/ElementalWarriorWine/bin/wineserver" -w

    # Extract WinMetadata
        7z x "$directory/Winmetadata.zip" -o"$metadata_dir"
        rm "$directory/Winmetadata.zip"

    # WINETRICKS setup
    log "Configuring Wine environment..."
    WINEPREFIX="$directory" winetricks --unattended dotnet48 corefonts
    WINEPREFIX="$directory" winetricks renderer=vulkan

    # Set Windows version
    "$directory/ElementalWarriorWine/bin/winecfg" -v win11

    log "Setup completed successfully!"
}

# Run main function
main "$@"
