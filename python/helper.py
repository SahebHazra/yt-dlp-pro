#!/usr/bin/env python3
import sys
import json
import glob
import shlex
import subprocess
from pathlib import Path

# ============== Helper Functions ====================
def newest(pattern):
    files = glob.glob(pattern)
    if not files: return None
    return max(files, key=lambda f: Path(f).stat().st_mtime)

def load_info():
    f = newest("*.info.json")
    if not f: return None, None
    with open(f, encoding="utf-8") as fp: 
        return json.load(fp), f

def save_chapters(info):
    chapters = info.get("chapters", [])
    with open("chapters.json", "w", encoding="utf-8") as fp:
        json.dump(chapters, fp, indent=2, ensure_ascii=False)
    return chapters

def find_video():
    exts = ("*.mp4", "*.mkv", "*.webm", "*.mov", "*.avi", "*.flv")
    vids = []
    for e in exts: 
        vids.extend(Path(".").glob(e))
    if not vids: return None
    return max(vids, key=lambda p: p.stat().st_mtime)

def esc(s):
    return (
        str(s)
        .replace("\\", "\\\\")
        .replace("=", "\\=")
        .replace(";", "\\;")
        .replace("#", "\\#")
        .replace("\n", "\\\n")
    )

# ================= show_video_info =====================
def show_info():
    vid_select = shlex.split(sys.argv[2])
    url = sys.argv[3]
    print("URL      :", url)
    info, f = load_info()
    if info is None:
        cmd = ["yt-dlp", "--skip-download", "--no-warnings", "--quiet", "--write-info-json"]
        cmd.extend(vid_select)
        cmd.append(url)
        subprocess.run(cmd, check=True)
        info, f = load_info()
        if info is None:
            print("Failed to create info.json")
            return
            
    print("Title    :", info.get("title", "Unknown"))
    print("Duration :", info.get("duration_string", "Unknown"))
    size = info.get("filesize") or info.get("filesize_approx")

    if size: 
        print(f"Size     : {size/1024/1024:.1f} MB")
    else: 
        print("Size     : Unknown")

# =================== embed_metadata ========================
def embed():
    info, f = load_info()
    if not Path("chapters.json").exists() and info is None:
        print("Neither chapters.json nor info.json found")
        return

    video = find_video()
    if video is None:
        print("No video found")
        return
        
    if Path("chapters.json").exists():
        with open("chapters.json", encoding="utf-8") as fp:  
            chapters = json.load(fp)
    else:
        chapters = info.get("chapters", [])

    meta = Path("metadata.ffmeta")
    with meta.open("w", encoding="utf-8") as fp:
        fp.write(";FFMETADATA1\n")
        mapping = {
            "title": info.get("title"), 
            "artist": info.get("uploader"), 
            "album_artist": info.get("channel"), 
            "comment": info.get("webpage_url"), 
            "description": info.get("description"), 
            "date": info.get("upload_date"),
        }

        for k, v in mapping.items():
            if v: fp.write(f"{k}={esc(v)}\n")
        fp.write("\n")
        
        for c in chapters:
            fp.write("[CHAPTER]\n")
            fp.write("TIMEBASE=1/1000\n")
            fp.write(f"START={int(c['start_time']*1000)}\n")
            fp.write(f"END={int(c['end_time']*1000)}\n")
            fp.write(f"title={esc(c['title'])}\n\n")

    tmp = video.with_name(video.stem + "_tmp" + video.suffix)
    subprocess.run([
        "ffmpeg", "-y", "-loglevel", "error", "-i", str(video),
        "-i", str(meta), "-map_metadata", "1", "-map_chapters", "1",
        "-c", "copy", str(tmp)
    ], check=True)

    video.unlink()
    tmp.rename(video)
    meta.unlink(missing_ok=True)
    print("✅ Metadata embedded.")

# =====================================================
if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: helper.py [show-info|embed] ...")
        sys.exit(1)
        
    mode = sys.argv[1]
    try:
        if mode == "show-info": 
            show_info() 
        elif mode == "embed": 
            embed()
        else: 
            print("Unknown mode:", mode)
    except KeyboardInterrupt: 
        print("...")
    except Exception as e: 
        print(f"Error: {e}")