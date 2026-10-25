#!/bin/bash
# Part 3: Core Download & Metadata Embedding Module

handle_download() {
    # Determine Script Root Path for calling Python helper securely
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    PYTHON_HELPER="$SCRIPT_DIR/python/helper.py"

    while true; do
        echo
        echo "Choose download option:"
        echo "1) Custom format (choose manually)"
        echo "2) Best quality (video+audio merged)"
        echo "3) Audio only (Low --> High)"
        echo "4) Audio only (best original)"
        echo "5) Video only (best, no audio)"
        echo "6) Subtitles only (.srt)"
        echo "7) 260/144p (video+audio fallback)"
        echo "8) 480p (video+audio fallback)"
        echo "9) 720p (video+audio fallback)"
        echo "10) 720p-144p (video+audio : All fallback)"
        echo "11) 144p-720p (video+audio: All fall-up )"
        echo "12) Offline metadata embed only"
        echo "Q/q) To Quit"
        echo
        read -p "Enter choice | Want SUB [e.g. 2 y] : " CHOICE EXTRA
        echo 

        FORMAT=""
        AUDIOs="139-drc/139/139-1/249-drc/249/249-1/250/250-1/251/140"
        EXTRA_OPTS=()
        CHAPTER_OPTS=()
        JSON=""
        SUB=""
        EMBD=""

        [[ "$EXTRA" =~ ^([Jj]|[Ee])$ ]]  && JSON="TRUE"
        [[ "$EXTRA" =~ ^([Ss]|[Yy]|[Yy]es)$ ]] && SUB="TRUE"
        [[ "$EXTRA" =~ ^([Ss][Jj]|[Yy][Jj])$ ]] && SUB="TRUE" && JSON="TRUE"
        [[ "$EXTRA" =~ ^([Ss][Ee]|[Yy][Ee])$ ]] && SUB="TRUE" && EMBD="TRUE"
        
        if [[ $SUB == "TRUE" ]]; then
            echo "SUBTITLE: TRUE"
            EXTRA_OPTS=(--write-auto-subs --sub-lang "en-orig,en.*,hi.*" --sub-format srt --convert-subs srt)
        fi
        
        if [[ $JSON == "TRUE" ]]; then
            echo "CHAPTER_JSON: TRUE"
            CHAPTER_OPTS=(--print-to-file "%(chapters)#j" "chapters.json" )
        elif [[ $EMBD == "TRUE" ]]; then
            echo "JSON_EMBED: TRUE"
            CHAPTER_OPTS=(--embed-metadata)
        fi
        
        case $CHOICE in
            1) 
                echo "Fetching available formats..."
                read -r -a VID_SELECT_ARGS <<< "$VID_SELECT"
                yt-dlp -i -F "${VID_SELECT_ARGS[@]}" "$URL"   
                read -p "Enter format code (e.g., 136+140): " FORMAT
                break 
                ;;
            2) FORMAT="bestvideo+bestaudio"; break ;;
            3) FORMAT="($AUDIOs)" ; break ;;
            4) FORMAT="bestaudio"; break ;;
            5) FORMAT="(136/135/134)"; break ;;
            6)
                FORMAT=""
                EXTRA_OPTS+=(--skip-download --write-auto-subs --sub-langs en,en.* --sub-format srt --convert-subs srt)
                break
                ;;
            7) FORMAT="(394/133/242/160/278)+($AUDIOs)" ; break ;;
            8) FORMAT="(135/244/134/243)+($AUDIOs)" ; break ;;
            9) FORMAT="(136/247/135/244)+($AUDIOs)" ; break ;;
            10) FORMAT="(136/247/135/244/134/243/133/242/160/278/18)+($AUDIOs)" ; break ;;
            11) FORMAT="(160/278/133/242/134/243/135/244/136/247/18)+($AUDIOs)" ; break ;;
            12)  
                FORMAT="" 
                EXTRA_OPTS+=(--skip-download) 
                break
                ;;
            [Qq]) 
                END=1 
                return 1 
                ;;
            *) echo "❌ Invalid choice. Press Enter to retry..." ;;
        esac
    done

    # ------- Offline Embed -------
    # This mode operates on an existing folder and never downloads from the URL.
    if [[ "$CHOICE" == "12" ]]; then
        read -r -p "Folder containing the existing video [current directory]: " EMBED_DIR
        EMBED_DIR="${EMBED_DIR:-$PWD}"
        if [[ ! -d "$EMBED_DIR" ]]; then
            echo "Error: folder does not exist: $EMBED_DIR"
            return 1
        fi
        cd "$EMBED_DIR" || return 1
        read -r -p "Video filename to update: " EMBED_VIDEO
        if [[ -z "$EMBED_VIDEO" || ! -f "$EMBED_VIDEO" ]]; then
            echo "Error: enter an existing video filename in that folder."
            return 1
        fi
        echo "Merging available metadata into $EMBED_VIDEO..."
        python3 "$PYTHON_HELPER" embed "$EMBED_VIDEO"
        return $?
    fi

    # --- Create folder for playlist/video --- #
    [[ $PLAYLIST_TITLE == "NA" ]] && PLAYLIST_TITLE=$(basename "${URL%%\?*}")
    PLAYLIST_TITLE="$HOME/Desktop/$PLAYLIST_TITLE"
    mkdir -p "$PLAYLIST_TITLE"
    cd "$PLAYLIST_TITLE" || return 1

    LINK_DIR="$PLAYLIST_TITLE/link.txt"
    touch "$LINK_DIR"

    if [[ $CHOICE == 1 ]]; then
        echo -e "$URL  -- with format [ $FORMAT ] and $EXTRA\n\n" >> "$LINK_DIR"
    else
        echo -e "$URL  -- with format at [ $CHOICE ]th and $EXTRA position\n\n" >> "$LINK_DIR"
    fi

    # --- Show duration(s) before download ---
    echo
    echo "⏳ Fetching duration info..."
    python3 "$PYTHON_HELPER" show-info "$VID_SELECT" "$URL"

    # --- Download with retry ---
    echo
    echo "⬇ Downloading..."
    MAX_RETRIES=3
    RETRY_DELAY=6
    ATTEMPT=1

    read -r -a VID_SELECT_ARGS <<< "$VID_SELECT"
    DOWNLOAD_OPTS=("${CHAPTER_OPTS[@]}" "${VID_SELECT_ARGS[@]}" "${EXTRA_OPTS[@]}")
    [[ -n "$FORMAT" ]] && DOWNLOAD_OPTS+=(-f "$FORMAT")

    while [ "$ATTEMPT" -le "$MAX_RETRIES" ]; do
        echo "Attempt $ATTEMPT of $MAX_RETRIES..."
        if yt-dlp --continue -i "${DOWNLOAD_OPTS[@]}" \
           -o "%(playlist_index)s - %(title)s - %(id)s.%(ext)s" "$URL"; then
            echo "✅ Download completed!"
            if [[ "$JSON" != "TRUE" ]]; then
                VIDEO_FILE=$(find . -maxdepth 1 -type f \
                    \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" -o  -iname "*.mov" -o -iname "*.avi" -o -iname "*.flv" \) \
                    | head -n1)

                if [[ -n "$VIDEO_FILE" ]]; then
                    echo "Merging JSON into video..."
                    python3 "$PYTHON_HELPER" embed "$VIDEO_FILE"
                else
                    echo "Skipping metadata merge (no video downloaded)."
                fi
            fi
            break
        else
            echo "⚠ Download failed (attempt $ATTEMPT)."
            [ $ATTEMPT -lt $MAX_RETRIES ] && echo "⏳ Retrying in $RETRY_DELAY seconds..." && sleep $RETRY_DELAY
        fi
        ATTEMPT=$((ATTEMPT+1))
    done
}