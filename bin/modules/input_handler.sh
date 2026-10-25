#!/bin/bash
# Part 2: Input & Playlist Handler Module

handle_input() {
    [[ "$IS_KEYWORD" == "1" ]] || PLAYLIST_TITLE="NA"
    COUNT=0
    VID_SELECT=""
    NUM=""
    RANGE_INPUT=""
    TITLES_FILE="$(mktemp "${TMPDIR:-/tmp}/yt-titles.XXXXXX")"
    
    if [ "$IS_KEYWORD" != 1 ]; then
        while true; do
            read -p "Enter YouTube URL: " URL
            if [[ -z "$URL" ]]; then
                echo "⚠ Empty URL! Press Enter to retry..."
                continue
            elif [[ ! "$URL" =~ ^https?://[^[:space:]]+$ ]]; then
                echo "⚠ Invalid URL format! Press Enter to retry..."
                continue
            fi
            
            echo "✅ URL Format Looks Valid"
            if [[ "$URL" == *"list="* ]]; then
                echo "Detected: Playlist URL"
                readarray -t META < <(yt-dlp --flat-playlist --print "%(playlist_title)s||%(title)s" "$URL" 2>/dev/null)

                if [ ${#META[@]} -gt 0 ]; then
                    PLAYLIST_TITLE=$(echo "${META[0]}" | cut -d"|" -f1)
                    printf "%s\n" "${META[@]#*||}" > "$TITLES_FILE"
                    COUNT=$(wc -l < $TITLES_FILE)
                    break
                else
                    echo "⚠ Something Went Wrong!"
                    continue
                fi
            else
                echo "Detected: Single Media URL"
                break
            fi  
        done
    fi

    # --- Detect playlist or single video ---
    if [ "$COUNT" -gt 1 ]; then
        echo "👉 Playlist detected: \"$PLAYLIST_TITLE\""
        echo "   Contains $COUNT videos."
        echo

        head -20 "$TITLES_FILE" | nl -w3 -s") "
        if [ "$COUNT" -gt 20 ]; then
            echo "   ... ($((COUNT-20)) more videos)"
            read -p "Show full list? (y/n): " SHOWALL
            [[ "$SHOWALL" =~ ^[Yy]$ ]] && nl -w3 -s") " "$TITLES_FILE"
        fi
        echo

        while true; do
            echo "Download mode:"
            echo "1) Single video only"
            echo "2) Entire playlist"
            echo "3) Custom choose videos"
            echo ""
            read -p "Enter choice [1-3]: " MODE
            case $MODE in
                1|2|3) break ;;
                *) echo "❌ Invalid choice. Press Enter to retry..."; read ;;
            esac
        done
    else
        MODE=1
    fi

    VID_SELECT=""
    if [ "$MODE" == "1" ]; then
        if [ "$COUNT" -gt 1 ]; then
            read -p "Enter video number (default 1): " NUM
        fi
        NUM=${NUM:-1}
        VID_SELECT="--playlist-items $NUM"
    elif [ "$MODE" == "2" ]; then
        echo "⚠ You are about to download the ENTIRE playlist ($COUNT videos)."
        read -p "Are you sure? (y/n): " CONFIRM
        if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
            echo "❌ Cancelled."
            rm -f "$TITLES_FILE"
            return 1
        fi
    elif [ "$MODE" == "3" ]; then
        read -p "Enter video numbers (e.g. 5,6,7 or 10-15): " RANGE_INPUT
        VID_SELECT="--playlist-items $RANGE_INPUT"
    fi
    
    rm -f "$TITLES_FILE"
    return 0
}