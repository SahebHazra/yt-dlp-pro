#!/usr/bin/env python3
import json
import shlex
import subprocess
import sys
from pathlib import Path


VIDEO_EXTENSIONS = {".mp4", ".mkv", ".webm", ".mov", ".avi", ".flv"}


def find_video():
    videos = [
        path for path in Path(".").iterdir()
        if path.is_file() and path.suffix.lower() in VIDEO_EXTENSIONS
    ]
    if not videos:
        return None
    return max(videos, key=lambda path: path.stat().st_mtime)


def load_info_for_video(video):
    """Load metadata belonging to this video, never an arbitrary newest JSON."""
    exact = video.with_name(video.stem + ".info.json")
    if exact.is_file():
        with exact.open(encoding="utf-8") as fp:
            return json.load(fp)

    # Some yt-dlp configurations use a different filename. Only accept a
    # fallback when there is exactly one metadata file, avoiding mismatches.
    candidates = list(Path(".").glob("*.info.json"))
    if len(candidates) == 1:
        with candidates[0].open(encoding="utf-8") as fp:
            return json.load(fp)
    return None


def esc(value):
    return (
        str(value)
        .replace("\\", "\\\\")
        .replace("=", "\\=")
        .replace(";", "\\;")
        .replace("#", "\\#")
        .replace("\n", "\\\n")
    )


def show_info():
    if len(sys.argv) < 4:
        raise ValueError("Usage: helper.py show-info '<playlist args>' URL")

    vid_select = sys.argv[2]
    url = sys.argv[3]
    print("URL      :", url)

    cmd = [
        "yt-dlp", "--dump-single-json", "--no-warnings", "--quiet",
        *(shlex.split(vid_select)), url,
    ]
    result = subprocess.run(cmd, check=True, capture_output=True, text=True)
    info = json.loads(result.stdout)

    print("Title    :", info.get("title", "Unknown"))
    print("Duration :", info.get("duration_string", "Unknown"))
    size = info.get("filesize") or info.get("filesize_approx")
    print(f"Size     : {size / 1024 / 1024:.1f} MB" if size else "Size     : Unknown")


def embed(video_name=None):
    if video_name:
        video = Path(video_name)
        if not video.is_file() or video.suffix.lower() not in VIDEO_EXTENSIONS:
            raise FileNotFoundError(f"Video file not found or unsupported: {video_name}")
    else:
        video = find_video()
    if video is None:
        raise FileNotFoundError("No video found in the current directory")

    info = load_info_for_video(video)
    chapters_file = Path("chapters.json")
    if info is None and not chapters_file.is_file():
        raise FileNotFoundError(
            f"No matching metadata found for {video.name}, and chapters.json is missing"
        )

    if chapters_file.is_file():
        with chapters_file.open(encoding="utf-8") as fp:
            chapters = json.load(fp)
    else:
        chapters = (info or {}).get("chapters") or []

    meta = Path("metadata.ffmeta")
    mapping = {
        "title": (info or {}).get("title"),
        "artist": (info or {}).get("uploader"),
        "album_artist": (info or {}).get("channel"),
        "comment": (info or {}).get("webpage_url"),
        "description": (info or {}).get("description"),
        "date": (info or {}).get("upload_date"),
    }

    try:
        with meta.open("w", encoding="utf-8") as fp:
            fp.write(";FFMETADATA1\n")
            for key, value in mapping.items():
                if value:
                    fp.write(f"{key}={esc(value)}\n")
            fp.write("\n")
            for chapter in chapters:
                fp.write("[CHAPTER]\n")
                fp.write("TIMEBASE=1/1000\n")
                fp.write(f"START={int(chapter['start_time'] * 1000)}\n")
                fp.write(f"END={int(chapter['end_time'] * 1000)}\n")
                fp.write(f"title={esc(chapter.get('title', 'Chapter'))}\n\n")

        tmp = video.with_name(video.stem + "_tmp" + video.suffix)
        subprocess.run(
            [
                "ffmpeg", "-y", "-loglevel", "error", "-i", str(video),
                "-i", str(meta), "-map_metadata", "1", "-map_chapters", "1",
                "-c", "copy", str(tmp),
            ],
            check=True,
        )
        # Replace only after ffmpeg succeeds; the original remains intact on error.
        tmp.replace(video)
        print(f"Metadata embedded into {video.name}.")
    finally:
        meta.unlink(missing_ok=True)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: helper.py [show-info|embed] ...", file=sys.stderr)
        sys.exit(2)

    try:
        mode = sys.argv[1]
        if mode == "show-info":
            show_info()
        elif mode == "embed":
            embed(sys.argv[2] if len(sys.argv) > 2 else None)
        else:
            raise ValueError(f"Unknown mode: {mode}")
    except KeyboardInterrupt:
        print("Cancelled.", file=sys.stderr)
        sys.exit(130)
    except Exception as exc:
        print(f"Error: {exc}", file=sys.stderr)
        sys.exit(1)
