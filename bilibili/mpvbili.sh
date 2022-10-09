CACHE_DIR=$HOME/.cache/bilibili
[ ! -d $CACHE_DIR ] && { mkdir $CACHE_DIR; }

# requirements:
# you need mpv and lrc.lua to show danmaku on mpv screen.
# use danmu.js to receive danmu from bilibili.
# usage:    mpv_bili.sh --live [id]
function bilibili_live() {
    # fetch roomid
    json=$(curl -sG "https://api.live.bilibili.com/room/v1/Room/room_init" --data-urlencode "id="$1)
    [ `echo $json | jq '.code'` -ne 0 ] && { echo "No such room." >&2; exit 1; }
    [ `echo $json | jq '.data.live_status'` -eq 0 ] && { echo "This room is not live." >&2; exit 1; }

    # run mpv with danmu.
    danmufile=$CACHE_DIR/bilibili_live.danmaku
    roomid=$(echo $json | jq '.data.room_id')
    echo "danmu log has been directed to $danmufile file."
    node ./danmu.js $roomid >> $danmufile &
    mpv --scripts=$XDG_CONFIG_HOME/mpv/irc.lua:$XDG_CONFIG_HOME/mpv/scrollingsubs.lua \
        --script-opts=irc-log_file=$danmufile "https://live.bilibili.com/$1"

    # kill danmu.js and clear danmufile.
    kill `ps -aux | grep "danmu.js" | grep -v grep | awk '{print $2}'`
    [ $? -ne 0 ] && echo "error, danmu process is still running." >&2
    echo "" > $danmufile
}

# use yt-dlp to download .xml and convert it to .ass by danmaku2ass.
function bilibili_bv() {
    log=$CACHE_DIR/bilibili_bv.log

    # download xml first.
    title=$(yt-dlp --get-title $1 2>>$log)
    [ $? -ne 0 ] && { echo "something goes wrong. please check the error file."; exit 1; }
    xml=$CACHE_DIR/$title".danmaku.xml"
    ass=$CACHE_DIR/$title".ass"
    yt-dlp --write-subs --sub-format xml --skip-download -o $CACHE_DIR/$title $1 >>$log 2>&1
    [ $? -ne 0 ] && { echo "something goes wrong. please check the error file."; exit 1; }

    # convert xml to ass file.
    danmaku2ass -o $ass -s 1920x1080 -fn "Stolzl book" -fs 48 -a 0.8 -dm 10 -ds 10 $xml

    # start mpv with yt-dlp hook.
    mpv $1 --sub-file=$ass

    # clear cache file
    rm -f $xml $ass $log
}

case $1 in
"--live") bilibili_live $2 ;;
"--bv")   bilibili_bv   $2 ;;
esac
