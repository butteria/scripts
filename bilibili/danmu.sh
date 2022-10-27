#! /bin/sh
DANMU_LIVE_LOG="$CACHE_DIR/live.txt"
DANMU_LIVE_JS="./danmu.js"
DANMU_FONT=""


function xml2ass {
    local xml="$1"
    
    ./danmaku2ass.py -o "$xml.ass" -s 1920x1080 -fn "Stolzl book" \
        -fs 48 -a 0.8 -dm 10 -ds 10 "$xml"
    
    # return ass filename.
    echo "$xml.ass"
}



function download_danmu {
    local cid="$1"

    DANMU_API="http://api.bilibili.com/x/v1/dm/list.so"
    curl -sG "$DANMU_API" \
         --data-urlencode "oid=$cid" \
         --compressed -o "$CACHE_DIR/$cid.xml"

    # return xml filename.
    echo "$CACHE_DIR/$cid.xml"
}

function listen_danmu {
    # check DANMU_LIVE_JS file.
    [ ! -e "$DANMU_LIVE_JS" ] && {
        echo "${BASH_SOURCE[0]}: line ${BASH_LINENO[0]}: danmu.js file not found." >&2;
        exit 1; }
    
    node "$DANMU_LIVE_JS" "$1"
}
