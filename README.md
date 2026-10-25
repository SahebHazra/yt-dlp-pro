# 🚀 yt-dlp-pro

> A modular, lightweight, and feature-rich CLI wrapper around `yt-dlp` and `ffmpeg`, designed for seamless media downloading, playlist handling, interactive terminal previews, and automated chapter/metadata embedding.

[![Bash](https://img.shields.io/badge/Language-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Python](https://img.shields.io/badge/Python-3.8%2B-blue.svg)](https://www.python.org/)
[![DevOps Portfolio](https://img.shields.io/badge/Portfolio-DevOps%20Project-orange.svg)]()
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## 🏗 Project Architecture & Design

Unlike standard monolithic shell scripts, `yt-dlp-pro` is built using a **modular software design pattern**. It separates concerns into distinct components, making it maintainable, testable, and scalable:

```text
yt-dlp-pro/
├── bin/
│   ├── ytdlp-pro              # Main Orchestrator (CLI Entry point & Loop)
│   └── modules/
│       ├── search.sh          # Part 1: YouTube Search, Result Parsing & MPV Preview
│       ├── input_handler.sh   # Part 2: URL Validation, Playlist Detection & Modes
│       └── downloader.sh      # Part 3: Format Selection, Retries & Core Download Engine
├── python/
│   └── helper.py              # Python Helper: Chapter parsing & FFmpeg metadata embedding
├── install-ytd.sh            # Automated Dependency Installer & System Symlinker
├── Makefile                   # Build automation (install / uninstall)
├── requirements.md            # Detailed system dependencies documentation
└── README.md                  # Project Documentation


## 📦 Quick Installation Guide
You can automatically check and install dependencies using our automated installer script:

```bash
chmod +x install-ytd.sh
sudo ./install-ytd.sh
```


## ✨ Key Features

    Dual Modes: Search YouTube by keywords directly from the terminal or paste direct URLs/playlists.
    Interactive MPV Preview: Preview video search results instantly in mpv before committing to a download.
    Advanced Format Selection: Supports custom format strings, best audio/video merging, custom resolutions (144p to 1080p fallbacks), and subtitle extraction (.srt).
    Smart Chapter & Metadata Embedding: Automatically extracts video chapters, metadata (uploader, description, upload date), and embeds them cleanly into the media container using ffmpeg.
    Robust Error Handling & Retries: Built-in automated retries with delay timers for unstable network conditions.
    Global System Integration: Installs cleanly as a system command (ytdlp-pro) via an automated install script.

## 📋 System Requirements

Please check requirements.md for full details. Quick overview:

    Bash (v4.0+)
    Python (v3.8+)
    yt-dlp
    FFmpeg
    mpv (Optional, for media preview)

## 🖥️ Platform Support

**`yt-dlp-pro` is currently a Linux-first CLI application.** Its main workflow uses Bash scripts and Linux installation paths, so it is not a native Windows application and the Linux installer should not be run directly from PowerShell or CMD.

### Using it on Windows with WSL 2 (recommended)

You can run the Linux version on Windows through **Windows Subsystem for Linux (WSL 2)** with an Ubuntu distribution:

1. Open **PowerShell as Administrator** and install WSL:
   ```powershell
wsl --install -d Ubuntu
```
2. Restart if Windows asks, then open **Ubuntu** from the Start menu and complete its first-time setup.
3. In the Ubuntu terminal, install the dependencies:
   ```bash
sudo apt update
sudo apt install -y git make python3 ffmpeg mpv yt-dlp
```
4. Clone and install the project inside the Ubuntu terminal:
   ```bash
git clone https://github.com/SahebHazra/yt-dlp-pro.git
cd yt-dlp-pro
chmod +x install-ytd.sh
sudo ./install-ytd.sh
```
5. Start it from Ubuntu:
   ```bash
ytdlp-pro
```

**Notes**
- Run these Linux commands inside the **Ubuntu/WSL terminal**, not directly in PowerShell or CMD.
- Downloads are saved under the Linux user's `~/Desktop/` path inside WSL. This is not necessarily your Windows Desktop; you can access WSL files through Windows File Explorer using `\\wsl$\Ubuntu\home\<your-linux-username>\`.
- `mpv` previews may depend on your WSL GUI support and configuration. You can still use the direct URL/playlist workflow if previews are unavailable.
- **Native Windows support is not currently implemented or tested.** Running it directly in PowerShell/CMD would require a Windows-specific launcher, path handling, dependency setup, and testing.

---
## 📦 Installation

You can install yt-dlp-pro globally on your Linux system using either our automated installer or make:

Method 1: Automated Installer
```bash
git clone https://github.com/SahebHazra/yt-dlp-pro.git
cd yt-dlp-pro
chmod +x install-ytd.sh
sudo ./install-ytd.sh
```

Method 2: Using Makefile
```bash
sudo make install
```

Once installed, you can run the tool from anywhere in your terminal:
```bash
ytdlp-pro
```

## 🎮 Usage Guide

    Type ytdlp-pro in your terminal.
    Choose your input method:
        [1] Download via direct URL or Playlist URL.
        [2] Search YouTube using keywords, preview search hits with mpv, and pick one to download.
        [909] Exit
    Select your desired format or quality profile.
    Files are automatically downloaded and organized into ~/Desktop/<Playlist_or_Video_Title>/ along with embedded metadata and chapters!

## 🛠 Uninstallation

To completely remove yt-dlp-pro from your system:
```bash
sudo make uninstall
```

## 👤 Author

Saheb

    Goal: Java & DevOps Engineer
    Focused on building robust automation scripts, modular tooling,java applications, and linux-native infrastructure.
