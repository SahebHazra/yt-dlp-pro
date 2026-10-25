#!/bin/bash
# ============================================================
# Installation Script for yt-dlp-pro
# Author: Saheb
# ============================================================

# Ensure script is run with root privileges
if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run this script with sudo or as root:"
    echo "   sudo ./install-ytd.sh"
    exit 1
fi

echo "============================================"
echo "   Installing yt-dlp-pro Dependencies       "
echo "============================================"

# 1. Check and Install System Dependencies
APT_PACKAGES=("ffmpeg" "mpv" "python3")
MISSING_PACKAGES=()

for pkg in "${APT_PACKAGES[@]}"; do
    if ! command -v "$pkg" &>/dev/null; then
        echo "⚠ $pkg is not installed."
        MISSING_PACKAGES+=("$pkg")
    else
        echo "✅ $pkg is already installed."
    fi
done

if ! command -v yt-dlp &>/dev/null; then
    echo "⚠ yt-dlp is not installed via system package manager. Checking pip/pipx..."
    if ! python3 -m yt-dlp --version &>/dev/null && ! command -v yt-dlp &>/dev/null; then
        echo "⚠ yt-dlp not found. It will be installed/updated via pip/pipx."
        MISSING_PACKAGES+=("yt-dlp")
    else
        echo "✅ yt-dlp is already available."
    fi
else
    echo "✅ yt-dlp is already installed."
fi

if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
    echo
    read -p "Do you want to install missing packages (${MISSING_PACKAGES[*]}) via apt/pip? (y/n): " INSTALL_APT
    if [[ "$INSTALL_APT" =~ ^[Yy]$ ]]; then
        APT_TO_INSTALL=()
        INSTALL_YT_DLP=false
        for pkg in "${MISSING_PACKAGES[@]}"; do
            if [ "$pkg" = "yt-dlp" ]; then
                INSTALL_YT_DLP=true
            else
                APT_TO_INSTALL+=("$pkg")
            fi
        done
        if [ ${#APT_TO_INSTALL[@]} -gt 0 ]; then
            apt update && apt install -y "${APT_TO_INSTALL[@]}"
        fi
        if [ "$INSTALL_YT_DLP" = true ]; then
            if ! apt install -y yt-dlp; then
                echo "❌ Could not install yt-dlp. Install it manually, then rerun this script."
                exit 1
            fi
            if ! command -v yt-dlp &>/dev/null && ! python3 -m yt_dlp --version &>/dev/null; then
                echo "❌ yt-dlp installation could not be verified."
                exit 1
            fi
        fi
    else
        echo "⚠ Warning: Some features may not work without required packages."
    fi
fi

echo
echo "============================================"
echo "   Installing yt-dlp-pro System-Wide        "
echo "============================================"

# Define target paths
INSTALL_DIR="/usr/local/lib/yt-dlp-pro"
BIN_LINK="/usr/local/bin/ytdlp-pro"

# Stage the new version first so a failed copy does not destroy the current install.
STAGING_DIR="${INSTALL_DIR}.new.$"
BACKUP_DIR="${INSTALL_DIR}.backup.$"
WRAPPER_TMP="${BIN_LINK}.new.$"
cleanup() {
    rm -rf "$STAGING_DIR"
    rm -f "$WRAPPER_TMP"
}
trap cleanup EXIT

mkdir -p "$STAGING_DIR" || exit 1
echo "📂 Staging project files..."
if ! cp -r bin python "$STAGING_DIR/"; then
    echo "❌ Could not copy project files; existing installation was left unchanged."
    exit 1
fi
chmod +x "$STAGING_DIR/bin/ytdlp-pro" "$STAGING_DIR/bin/modules/"*.sh

cat > "$WRAPPER_TMP" << 'EOF'
#!/bin/bash
# Global launcher for yt-dlp-pro
exec /usr/local/lib/yt-dlp-pro/bin/ytdlp-pro "$@"
EOF
chmod +x "$WRAPPER_TMP" || exit 1

# Move the old install aside and roll back if activating the new version fails.
if [ -d "$INSTALL_DIR" ]; then
    mv "$INSTALL_DIR" "$BACKUP_DIR" || exit 1
fi
if ! mv "$STAGING_DIR" "$INSTALL_DIR"; then
    [ -d "$BACKUP_DIR" ] && mv "$BACKUP_DIR" "$INSTALL_DIR"
    echo "❌ Could not activate the new installation."
    exit 1
fi
if ! mv "$WRAPPER_TMP" "$BIN_LINK"; then
    rm -rf "$INSTALL_DIR"
    [ -d "$BACKUP_DIR" ] && mv "$BACKUP_DIR" "$INSTALL_DIR"
    echo "❌ Could not install the launcher; restored the previous version."
    exit 1
fi
rm -rf "$BACKUP_DIR"
trap - EXIT

echo
echo "============================================"
echo "✅ Installation Completed Successfully!"
echo "============================================"
echo "You can now run your tool from anywhere in the terminal by typing:"
echo "👉 ytdlp-pro"
echo "============================================"