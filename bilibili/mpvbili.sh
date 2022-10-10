# bilibili api details on https://github.com/SocialSisterYi/bilibili-API-collect.
CACHE_DIR=$HOME/.cache/bilibili
[ ! -d $CACHE_DIR ] && { mkdir $CACHE_DIR; }

# requirements:
# you need mpv and lrc.lua to show danmaku on mpv screen.
# use danmu.js to receive danmu from bilibili.
# usage:    mpvbili.sh --live [id]
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

# use yt-dlp to download .xml and convert it to .ass by danmaku2ass.py.
# usage:    mpvbili.sh --bv [id]
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
    ./danmaku2ass.py -o $ass -s 1920x1080 -fn "Stolzl book" -fs 48 -a 0.8 -dm 10 -ds 10 $xml

    # start mpv with yt-dlp hook.
    mpv $1 --sub-file=$ass

    # clear cache file
    rm -f $xml $ass $log
}

function bilibili_cv_search() {
    # get cookies.
    cookies=`cat ./cookies`
    res=`curl -sG 'http://api.bilibili.com/x/web-interface/search/type' \
        --data-urlencode 'search_type=media_bangumi' \
        --data-urlencode "keyword=$1" \
        -b "SESSDATA=$cookies"`
    message=`echo $res | jq -r '.message'`
    [[ "$message" != "0" ]] && { echo "$message"; exit 1; }

    pages=( `echo $res | jq -r '.data | "\(.numResults) \(.numPages)"'` )

    # titles without html tag.
    echo "${pages[0]} search results found."
    choose=`echo $res | jq -r '.data.result[].title' | sed 's/<[^>]*>//g' | dmenu -ix -fn "JetBrainsMono" -l 15 -c -p "results?"`
    [[ $? != 0 ]] && { echo "dmenu selection abort by user."; exit 1; }
    mid=( `echo $res | jq -r ".data.result[$choose].media_id"` )
    
    # use mdid to get more info.
    detailres=`curl -sG 'http://api.bilibili.com/pgc/review/user' \
        --data-urlencode "media_id=$mid" \
        -b "SESSDATA=$cookies"`
    message=`echo $detailres | jq -r '.message'`
    [[ "$message" != "success" ]] && { echo "$message"; exit 1; }
    ssid=`echo $detailres | jq -r '.result.media.season_id'`

    # run bilibili_cv func.
    bilibili_cv $ssid
}

# usage: mpvbili.sh --cv [seasonid] 
function bilibili_cv() {
    # get season info.
    season_info=`curl -sG 'http://api.bilibili.com/pgc/view/web/season' \
        --data-urlencode "season_id=$1"`
    message=`echo $season_info | jq -r '.message'`
    [[ "$message" != "success" ]] && { echo "$message"; exit 1; }

    # choose video.
    index=`echo $season_info \
        | jq -r '.result.episodes[] | "\(.share_copy) \(.badge_info.text)"' \
        | dmenu -ix -fn "JetBrainsMono" -l 15 -c -p "episode?"`
    [[ $? != 0 ]] && { echo "dmenu selection abort by user."; exit 1; }
    
    # get cid for .danmu and epid for video real url.
    cid=`echo $season_info | jq -r ".result.episodes[$index].cid"`
    epidbase=`curl -sG 'http://api.bilibili.com/pgc/view/web/season' \
        --data-urlencode "season_id=$1" \
        | jq '.result.episodes[0].id'`
    epid=$( expr $epidbase + $index )

    # try to get real url.
    playlists_info=`curl -sG 'https://api.bilibili.com/pgc/player/web/playurl' \
        --data-urlencode "ep_id=$epid" \
        --data-urlencode 'qn=64'`
    message=`echo $playlists_info | jq -r '.message'`
    [[ "$message" != "success" ]] && { echo "$message"; exit 1; }
    url=`echo $playlists_info | jq -r '.result.durl[0].url'`
    
    # get danmu.
    danmu_ass="$CACHE_DIR/$cid.danmu.ass"
    danmu_xml="$CACHE_DIR/$cid.danmu.xml"
    ./danmu.sh $cid $danmu_xml
    ./danmaku2ass.py -o $danmu_ass -s 1920x1080 -fn "Stolzl book" \
        -fs 48 -a 0.8 -dm 10 -ds 10 $danmu_xml
    # run mpv.
    mpv --sub-file="$danmu_ass" $url

    # rm danmu locally.
    rm -f "$danmu_ass" "$danmu_xml"
}

case $1 in
    "--live") bilibili_live $2 ;;
    "--bv")   bilibili_bv   $2 ;;
    "--cv")   bilibili_cv   $2 ;;
    "--cvsearch")   bilibili_cv_search $2;;
esac
