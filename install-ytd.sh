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
            python3 -m pip install --upgrade --user yt-dlp || pip3 install --upgrade --user yt-dlp || apt install -y yt-dlp || true
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

# Clean up old installations if any
if [ -d "$INSTALL_DIR" ]; then
    echo "🔄 Updating existing installation in $INSTALL_DIR..."
    rm -rf "$INSTALL_DIR"
fi

# Create system lib directory
mkdir -p "$INSTALL_DIR"

# Copy bin modules and python helper into lib directory
echo "📂 Copying project files to $INSTALL_DIR..."
cp -r bin "$INSTALL_DIR/"
cp -r python "$INSTALL_DIR/"

# Create a robust wrapper script in /usr/local/bin/ytdlp-pro
echo "🔗 Creating global symlink / command..."
cat << 'EOF' > "$BIN_LINK"
#!/bin/bash
# Global launcher for yt-dlp-pro
exec /usr/local/lib/yt-dlp-pro/bin/ytdlp-pro "$@"
EOF

# Make the wrapper executable
chmod +x "$BIN_LINK"
chmod -R +x "$INSTALL_DIR/bin/"

echo
echo "============================================"
echo "✅ Installation Completed Successfully!"
echo "============================================"
echo "You can now run your tool from anywhere in the terminal by typing:"
echo "👉 ytdlp-pro"
echo "============================================"