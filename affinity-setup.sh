#!/bin/bash

# Set strict mode
set -euo pipefail

# Global logfile (master) and per-step logs are written to /tmp
MASTER_LOG="/tmp/affinity_setup.log"
: > "$MASTER_LOG"  # truncate at start

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Logging helpers (print to terminal and append to master log)
log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1" | tee -a "$MASTER_LOG"
}

log_success() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')] ✓${NC} $1" | tee -a "$MASTER_LOG"
}

log_error() {
    echo -e "${RED}[$(date '+%H:%M:%S')] ✗${NC} $1" | tee -a "$MASTER_LOG" >&2
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%H:%M:%S')] ⚠${NC} $1" | tee -a "$MASTER_LOG"
}

log_step() {
    echo -e "${CYAN}[$(date '+%H:%M:%S')] ▶${NC} ${BOLD}$1${NC}" | tee -a "$MASTER_LOG"
}

log_substep() {
    echo -e "${MAGENTA}[$(date '+%H:%M:%S')]   →${NC} $1" | tee -a "$MASTER_LOG"
}

# Helper to run a command, stream output to terminal and to a step logfile, and fail on non-zero exit
run_and_log() {
    # usage: run_and_log "/tmp/somestep.log" command arg1 arg2 ...
    local step_log="$1"; shift
    : > "$step_log"
    # Run the command, capture both stdout/stderr, stream to terminal and step_log, preserve exit code
    "$@" 2>&1 | tee -a "$step_log" | sed -u 's/^/    /' | tee -a "$MASTER_LOG"
    local rc=${PIPESTATUS[0]}
    if [ $rc -ne 0 ]; then
        log_error "Command failed (exit $rc). See $step_log and $MASTER_LOG"
        return $rc
    fi
    return 0
}

# Function to check dependencies
check_dependencies() {
    local deps=("wget" "curl" "7z" "jq" "git" "winetricks")
    local missing_deps=()

    log_step "Checking dependencies..."
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done

    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        log "Please install them with: sudo apt update && sudo apt install ${missing_deps[*]}"
        exit 1
    fi
    log_success "All dependencies are installed"
}

# Function to install rum
install_rum() {
    log_step "Setting up rum (Wine prefix manager)..."
    if command -v rum &> /dev/null; then
        log_success "rum is already installed"
        return 0
    fi

    if [ ! -d "$HOME/Documents/rum" ]; then
        log_substep "Cloning rum repository..."
        run_and_log "/tmp/rum_clone.log" git clone https://gitlab.com/xkero/rum "$HOME/Documents/rum"
        log_success "Repository cloned"
    else
        log_substep "Repository already exists"
    fi

    if [ ! -f "/usr/local/bin/rum" ]; then
        log_substep "Installing rum to /usr/local/bin..."
        run_and_log "/tmp/rum_install.log" sudo cp "$HOME/Documents/rum/rum" "/usr/local/bin/rum"
        run_and_log "/tmp/rum_chmod.log" sudo chmod +x "/usr/local/bin/rum"
        log_success "rum installed successfully"
    else
        log_substep "rum already in /usr/local/bin"
    fi
}

# Function to safely create directory
create_directory() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        run_and_log "/tmp/mkdir_$(basename "$dir").log" sudo mkdir -p "$dir"
    fi
}

# Simplified download with tee logging (lets curl handle progress)
download_file() {
    local url="$1"
    local output="$2"
    local description="$3"
    local step_log="/tmp/download_$(basename "$output").log"

    log_substep "Downloading $description..."
    # create parent dir if needed
    mkdir -p "$(dirname "$output")"

    # Use curl; stream progress and output to step log and master log
    if run_and_log "$step_log" curl -L --fail --progress-bar -o "$output" "$url"; then
        log_success "$description downloaded to $output"
        return 0
    else
        log_error "Failed to download $description from $url"
        return 1
    fi
}

# Function to install Affinity
install_affinity() {
    local wine_build_name="$1"
    local wineprefix="$2"
    local installer_url="https://downloads.affinity.studio/Affinity%20x64.exe"
    local installer_path="$HOME/Downloads/Affinity_x64.exe"
    local step_log="/tmp/affinity_install.log"

    log_step "Installing Affinity Suite..."

    # Download Affinity installer
    if [ ! -f "$installer_path" ]; then
        download_file "$installer_url" "$installer_path" "Affinity installer"
    else
        log_substep "Installer already downloaded: $installer_path"
    fi

    # Launch Affinity installer using rum and stream logs
    log_substep "Launching installer (GUI will appear). Logs: $step_log"
    log_warning "GUI installer will appear; please follow the installer wizard."

    # Use run_and_log so the user's terminal sees progress and logs are saved
    if run_and_log "$step_log" rum "$wine_build_name" "$wineprefix" wine "$installer_path"; then
        log_success "Installer launched successfully"
    else
        log_error "Installer failed to launch. See $step_log and $MASTER_LOG"
        return 1
    fi

    # Wait for wineserver to finish
    wineserver -w 2>/dev/null || true

    log_success "Affinity installation step finished (check GUI to complete install)"
    return 0
}

# Function to install AffinityPluginLoader
install_plugin_loader() {
    local wineprefix="$1"
    local affinity_dir="$wineprefix/drive_c/Program Files/Affinity/Affinity"
    local step_log="/tmp/plugin_loader.log"

    log_step "Installing AffinityPluginLoader + WineFix..."

    if [ ! -d "$affinity_dir" ]; then
        log_error "Affinity directory not found: $affinity_dir"
        log "Please ensure Affinity was installed correctly before running plugin installer"
        return 1
    fi

    log_substep "Affinity directory verified: $affinity_dir"

    local download_url="https://github.com/noahc3/AffinityPluginLoader/releases/latest/download/affinitypluginloader-plus-winefix.tar.xz"
    local temp_file="/tmp/affinitypluginloader-plus-winefix.tar.xz"

    download_file "$download_url" "$temp_file" "AffinityPluginLoader bundle"

    log_substep "Extracting plugin files to $affinity_dir..."
    if run_and_log "$step_log" sudo tar -xf "$temp_file" -C "$affinity_dir"; then
        log_success "Plugin files extracted"
    else
        log_error "Failed to extract plugin files. See $step_log"
        return 1
    fi

    rm -f "$temp_file"
    log_success "AffinityPluginLoader installed successfully"
    return 0
}

# Main script execution
main() {
    # Configuration
    local wine_build_name="affinity-photo3-wine9.13-part3"
    local wines_dir="/opt/wines"
    local wineprefix="$HOME/.wineAffinityv3"
    local repo="22-pacific/ElementalWarrior-wine-binaries"
    local filename="ElementalWarriorWine.zip"

    echo ""
    echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║       Affinity Complete Setup Script       ║${NC}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════╝${NC}"
    echo ""

    # Check dependencies
    check_dependencies

    # Install rum
    install_rum

    # Create wines directory and set permissions
    log_step "Setting up Wine directories..."
    create_directory "$wines_dir"
    run_and_log "/tmp/chown_wines.log" sudo chown "$USER:$USER" "$wines_dir" || true
    log_success "Wine directories ready"

    # Fetch latest release information
    log_step "Fetching Wine build information..."
    local release_info_log="/tmp/release_info.log"
    if run_and_log "$release_info_log" curl -s "https://api.github.com/repos/$repo/releases/latest" > /tmp/release_info.json; then
        log_success "Release information retrieved"
    else
        log_error "Failed to fetch release information from GitHub (see $release_info_log)"
        exit 1
    fi

    local download_url
    download_url=$(jq -r ".assets[] | select(.name == \"$filename\") | .browser_download_url" /tmp/release_info.json || true)

    if [ -z "$download_url" ]; then
        log_error "Wine build file not found in latest release for $filename"
        exit 1
    fi

    # Download and verify wine binaries
    log_step "Downloading Wine binaries..."
    download_file "$download_url" "$wines_dir/$filename" "Wine binaries (approx 400MB)"

    # Define the paths
    local wine_zip_path="$wines_dir/$filename"
    local target_dir="$wines_dir/$wine_build_name"

    # Extract or skip if exists
    if [ -d "$target_dir/bin" ] && [ -f "$target_dir/bin/wine" ]; then
        log_warning "Wine build already exists, skipping extraction"
        run_and_log "/tmp/rm_winezip.log" sudo rm -f "$wine_zip_path" || true
    else
        create_directory "$target_dir"
        log_step "Extracting Wine binaries (this may take a minute)..."
        if run_and_log "/tmp/wine_extract.log" sudo 7z x "$wine_zip_path" -o"$target_dir" -y; then
            log_success "Wine binaries extracted"
        else
            log_error "Failed to extract Wine binaries (see /tmp/wine_extract.log)"
            exit 1
        fi

        # Organize files if needed
        if [ -d "$target_dir/ElementalWarriorWine" ]; then
            log_substep "Organizing files..."
            if run_and_log "/tmp/rsync_wine.log" sudo rsync -a "$target_dir/ElementalWarriorWine/" "$target_dir/"; then
                sudo rm -rf "$target_dir/ElementalWarriorWine"
                log_success "Files organized"
            else
                log_error "Failed to organize Wine files"
                exit 1
            fi
        fi

        # Clean up the zip file
        sudo rm -f "$wine_zip_path" || true
    fi

    # Create wine64 symlink
    log_substep "Creating wine64 symlink..."
    if run_and_log "/tmp/wine64_symlink.log" sudo ln -sf "$target_dir/bin/wine" "$target_dir/bin/wine64"; then
        log_success "Wine64 symlink created"
    else
        log_error "Failed to create wine64 symlink"
        exit 1
    fi

    # Create wineprefix directory
    log_step "Setting up Wine prefix..."
    mkdir -p "$wineprefix"

    # Initialize wineprefix using rum
    log_substep "Initializing Wine prefix (please wait)..."
    if run_and_log "/tmp/wineboot.log" rum "$wine_build_name" "$wineprefix" wineboot --init; then
        log_success "Wine prefix initialized"
    else
        log_error "Failed to initialize Wine prefix (see /tmp/wineboot.log)"
        exit 1
    fi

    # Wait for wineserver to finish
    wineserver -w 2>/dev/null || true

    # Download WinMetadata
    log_step "Downloading WinMetadata..."
    if ! download_file "https://archive.org/download/win-metadata/WinMetadata.zip" \
                      "$wineprefix/WinMetadata.zip" \
                      "WinMetadata"; then
        log_error "Failed to download WinMetadata"
        exit 1
    fi

    # Install dependencies with winetricks (each step logged)
    log_step "Installing Windows dependencies (this will take several minutes)..."
    log_substep "Installing .NET Framework 4.8..."
    if run_and_log "/tmp/dotnet48.log" rum "$wine_build_name" "$wineprefix" winetricks --unattended dotnet48; then
        log_success ".NET Framework 4.8 installed"
    else
        log_error "Failed to install .NET 4.8 (see /tmp/dotnet48.log)"
        exit 1
    fi

    log_substep "Installing core fonts..."
    if run_and_log "/tmp/corefonts.log" rum "$wine_build_name" "$wineprefix" winetricks --unattended corefonts; then
        log_success "Core fonts installed"
    else
        log_warning "Failed to install core fonts (non-critical). See /tmp/corefonts.log"
    fi

    log_substep "Installing Visual C++ runtime..."
    if run_and_log "/tmp/vcrun2022.log" rum "$wine_build_name" "$wineprefix" winetricks --unattended vcrun2022; then
        log_success "Visual C++ runtime installed"
    else
        log_error "Failed to install Visual C++ runtime (see /tmp/vcrun2022.log)"
        exit 1
    fi

    log_substep "Configuring Vulkan renderer..."
    if run_and_log "/tmp/vulkan.log" rum "$wine_build_name" "$wineprefix" winetricks renderer=vulkan; then
        log_success "Vulkan renderer configured"
    else
        log_warning "Failed to configure Vulkan renderer (non-critical). See /tmp/vulkan.log"
    fi

    # Set Windows version to 11 (best-effort)
    log_substep "Setting Windows version to 11..."
    if run_and_log "/tmp/winecfg.log" rum "$wine_build_name" "$wineprefix" wine winecfg -v win11; then
        log_success "Windows 11 mode enabled"
    else
        log_warning "Failed to set Windows 11 mode (non-critical)"
    fi

    # Extract WinMetadata files
    log_step "Installing WinMetadata..."
    mkdir -p "$wineprefix/drive_c/windows/system32/WinMetadata"
    if run_and_log "/tmp/winmetadata.log" 7z x "$wineprefix/WinMetadata.zip" -o"$wineprefix/drive_c/windows/system32/WinMetadata" -y; then
        log_success "WinMetadata extracted"
    else
        log_error "Failed to extract WinMetadata (see /tmp/winmetadata.log)"
        exit 1
    fi

    # Move files if nested subdir present
    if [ -d "$wineprefix/drive_c/windows/system32/WinMetadata/WinMetadata" ]; then
        mv "$wineprefix/drive_c/windows/system32/WinMetadata/WinMetadata"/* \
           "$wineprefix/drive_c/windows/system32/WinMetadata/" 2>/dev/null || true
        rmdir "$wineprefix/drive_c/windows/system32/WinMetadata/WinMetadata" 2>/dev/null || true
    fi

    rm -f "$wineprefix/WinMetadata.zip" || true
    log_success "Wine environment setup completed"

    # Install Affinity
    install_affinity "$wine_build_name" "$wineprefix"

    # Install AffinityPluginLoader
    install_plugin_loader "$wineprefix"

    echo ""
    echo -e "${BOLD}${GREEN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${GREEN}║       Setup Completed Successfully! 🎉     ║${NC}"
    echo -e "${BOLD}${GREEN}╚════════════════════════════════════════════╝${NC}"
    echo ""
    log_success "Wine build: $wines_dir/$wine_build_name"
    log_success "Wineprefix: $wineprefix"
    echo ""
    log "To launch Affinity applications:"
    echo -e "  ${CYAN}rum $wine_build_name $wineprefix wine \"C:\\Program Files\\Affinity\\Affinity\\Photo.exe\"${NC}"
    echo ""
}

# Check if script is run as root
if [ "$EUID" -eq 0 ]; then
    log "ERROR: This script should not be run as root"
    exit 1
fi

# Run main function
main "$@"
