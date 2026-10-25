# Makefile for yt-dlp-pro 

.PHONY: install uninstall check force-install-dependency

install:
	@echo "Installing yt-dlp-pro..."
	@sudo ./install-ytd.sh

uninstall:
	@echo "Uninstalling yt-dlp-pro..."
	@sudo rm -rf /usr/local/lib/yt-dlp-pro
	@sudo rm -f /usr/local/bin/ytdlp-pro
	@echo "✅ yt-dlp-pro uninstalled successfully."

check:
	@echo "Checking dependencies and yt-dlp latest version..."
	@which ffmpeg mpv python3 || echo "Some core dependencies are missing."
	@python3 -c "import yt_dlp" 2>/dev/null && echo "yt-dlp is installed in Python." || (pipx --version >/dev/null 2>&1 && echo "yt-dlp can be checked via pipx.") || which yt-dlp >/dev/null 2>&1 && echo "yt-dlp found in PATH." || echo "yt-dlp is not installed."
	@pipx run yt-dlp --version 2>/dev/null || python3 -m yt_dlp --version 2>/dev/null || yt-dlp --version 2>/dev/null || echo "Could not retrieve yt-dlp version."

force-install-dependency:
	@echo "Force installing/updating dependencies..."
	@(pip install --upgrade yt-dlp 2>/dev/null) || (pipx upgrade yt-dlp 2>/dev/null || pipx install yt-dlp 2>/dev/null) || (sudo apt-get update && sudo apt-get install -y yt-dlp ffmpeg mpv python3) || echo "Failed to force install dependencies."