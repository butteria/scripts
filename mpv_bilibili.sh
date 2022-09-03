function bili_live() {
    # get real room_id.
    room_id=$(curl -sG "https://api.live.bilibili.com/room/v1/Room/room_init" --data-urlencode "id="$1 | jq ".data.room_id")
    danmu_tmpfile=$(cat $XDG_CONFIG_HOME/mpv/scripts/irc.lua | grep -E 'log_file = ".+"' | grep -o '".*"' | sed 's/"//g')
    echo "danmu log has been directed to $danmu_tmpfile."

    node ./websoc_danmu.js $room_id >> $danmu_tmpfile &
    mpv https://live.bilibili.com/$1
    kill `ps -aux | grep "websoc_danmu.js" | head -1 | awk '{print $2}'`
    echo "" > $danmu_tmpfile
}

# use yt-dlp to download and mpv to watch bilibili video with danmaku...
function bili_bv(){
    # cache file.
    CACHE_DIR=$HOME/.cache/bilibili
    if [ ! -d $CACHE_DIR ] ; then
        mkdir $CACHE_DIR
    fi
    
    # download xml first.
    title=$(yt-dlp --get-title $1 2>>$CACHE_DIR/mpv_bilibili.log)
    [ $? -ne 0 ] && { echo "something goes wrong. please check the error file."; exit 1; }
    xml_file=$title".danmaku.xml"
    ass_file=$title".ass"
    yt-dlp --write-subs --sub-format xml --skip-download  -o $CACHE_DIR/$title $1 >>$CACHE_DIR/mpv_bilibili.log 2>&1
    [ $? -ne 0 ] && { echo "something goes wrong. please check the error file."; exit 1; }
    
    # convert xml to ass file.
    danmaku2ass -o $CACHE_DIR/$ass_file -s 1920x1080 -fn "Stolzl book" -fs 48 -a 0.8 -dm 5 -ds 5 $CACHE_DIR/$xml_file
    
    # start mpv with yt-dlp hook.
    mpv $1 --sub-file=$CACHE_DIR/$ass_file
}

case $1 in
"--live") bili_live $2 ;;
esac

