# use yt-dlp to download and mpv to watch bilibili video with danmaku...

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
