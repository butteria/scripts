function watch_live {
    # get live room info.
    local LIVE_ROOM_API="https://api.live.bilibili.com/room/v1/Room/room_init"
    live_info=$(curl -sG "$LIVE_ROOM_API" --data-urlencode "id="$1)
    message=$(echo $live_info | jq -r '.message')
    [[ "$message" != "ok" ]] && { echo "$message" >&2; exit 1; }

    # use websocket to receive danmu.
    room_id=$(echo $live_info | jq '.data.room_id')
    get_danmu_live "$room_id" > "$DANMU_LIVE_LOG" &
    [[ $? != 0 ]] && { exit 1; }
    echo "danmu log has been directed to $DANMU_LIVE_LOG."

    mpv --scripts=$XDG_CONFIG_HOME/mpv/irc.lua:$XDG_CONFIG_HOME/mpv/scrollingsubs.lua \
        --script-opts=irc-log_file="$DANMU_LIVE_LOG" "https://live.bilibili.com/$1"

    # kill danmu.js and clear danmu file.
    kill `ps -aux | grep "danmu.js" | grep -v grep | awk '{print $2}'`
    rm -rf "$DANMU_LIVE_LOG"
}
