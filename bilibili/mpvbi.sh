# bilibili api details on https://github.com/SocialSisterYi/bilibili-API-collect.
CACHE_DIR=$HOME/.cache/bilibili
[ ! -d $CACHE_DIR ] && { mkdir $CACHE_DIR; }

# load module.
source ./fanju.sh
source ./debug.sh
source ./danmu.sh
source ./live.sh


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


case $1 in
    "--live") watch_live $2 ;;
    "--bv")   bilibili_bv   $2 ;;
    "--cv")   watch_fanju   $2 ;;
    "--cvsearch")   search_fanju $2;;
esac
