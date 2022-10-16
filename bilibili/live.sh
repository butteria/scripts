function watch_live {
    # get live room info.
    local LIVE_ROOM_API="https://api.live.bilibili.com/room/v1/Room/room_init"
    live_info=$(curl -sG "$LIVE_ROOM_API" --data-urlencode "id="$1)
    message=$(echo $live_info | jq -r '.message')
    [[ "$message" != "ok" ]] && { echo "$message"; exit 1; }

    # use websocket to receive danmu.
    room_id=$(echo $live_info | jq '.data.room_id')
    echo "try to listen to room $room_id..."
    listen_danmu "$room_id" > "$DANMU_LIVE_LOG" &
    [[ $? != 0 ]] && { 
        echo "${BASH_SOURCE[0]}: line ${BASH_LINENO[0]}: listen room $room_id failed." >&2;
        exit 1; }
    echo "succeed,danmu log is directed to $DANMU_LIVE_LOG."

    # run mpv.
    mpv --scripts=$XDG_CONFIG_HOME/mpv/irc.lua:$XDG_CONFIG_HOME/mpv/scrollingsubs.lua \
        --script-opts=irc-log_file="$DANMU_LIVE_LOG" "https://live.bilibili.com/$1" 1>/dev/null

    # kill danmu.js and clear danmu file.
    kill `ps -aux | grep "danmu.js" | grep -v grep | awk '{print $2}'`
    rm -rf "$DANMU_LIVE_LOG"
}
