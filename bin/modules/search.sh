#!/bin/bash
# Part 1: YouTube Search Module

handle_search() {
    local RANGE=10
    read -p "Enter search keyword: " INPUT
    [[ -z "$INPUT" ]] && echo "❌ No keyword entered." && return 1
    
    echo "⏳ Searching YouTube..."
    RESULTS=$(yt-dlp "ytsearch$RANGE:${INPUT}" --flat-playlist --no-warnings \
              --print "https://youtu.be/%(id)s | %(title)s | %(channel)s | %(duration_string)s")
    RCOUNT=$(echo "$RESULTS" | wc -l)
    
    if [ -z "$RESULTS" ] || [ "$RCOUNT" -eq 0 ]; then
        echo "⚠ No results found for \"$INPUT\""
        return 1
    fi
    
    echo
    echo "📋 Search results for \"$INPUT\":"
    echo "$RESULTS" | nl -w2 -s") "
    echo
    
    PLAYLIST_TITLE="$INPUT"
    LOCATION="$HOME/Desktop/$PLAYLIST_TITLE"
    mkdir -p "$LOCATION"
    echo -e ".\n\n\n.📋 Search results for \"$INPUT\":\n" >> "$LOCATION/KeywordSearch.txt"
    echo -e "$RESULTS" | nl -w2 -s") - " >> "$LOCATION/KeywordSearch.txt"
        
    while true; do
        read -p "Enter number to preview, 'd' to download, or 'q' to back: " CHOICE
        case "$CHOICE" in
            [Qq]) 
                END=1 
                return 1 
                ;;
            [Dd])
                read -p "Enter number to download: " NUM
                if [[ $NUM -gt 0 && $NUM -lt $((RANGE+1)) ]]; then
                    VIDEO_URL=$(echo "$RESULTS" | sed -n "${NUM}p" | awk '{print $1}')
                    [[ -z "$VIDEO_URL" ]] && echo "⚠ Invalid selection!" && continue
                    URL="$VIDEO_URL"
                    IS_KEYWORD=1
                    return 0
                else
                    echo "⚠ Invalid choice."
                fi
                ;;
            *)
                if [[ $CHOICE -gt 0 && $CHOICE -lt $((RANGE+1)) ]]; then
                    VIDEO_URL=$(echo "$RESULTS" | sed -n "${CHOICE}p" | awk '{print $1}')
                    [[ -z "$VIDEO_URL" ]] && echo "⚠ Invalid selection!" && continue
                    echo "🎬 Playing in mpv: $VIDEO_URL"
                    mpv "$VIDEO_URL" &>/dev/null &
                else
                    echo "⚠ Invalid choice."
                fi
                ;;
        esac
    done
}