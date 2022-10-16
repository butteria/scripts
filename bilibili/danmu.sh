#! /bin/sh
DANMU_LIVE_LOG="$CACHE_DIR/live.danmu"
DANMU_LIVE_JS="./adanmu.js"

function get_danmu_xml {
    DANMU_API="http://api.bilibili.com/x/v1/dm/list.so"
    curl -sG $DANMU_API \
         --data-urlencode "oid=$1" \
         --compressed -o "$2"
}

function get_danmu_live {
    # check DANMU_LIVE_JS file.
    [ ! -e "$DANMU_LIVE_JS" ] && { \
        echo "[$0]: func:${FUNCNAME[0]} ${BASH_LINENO[0]} \
            No $DANMU_LIVE_JS file to receive live danmu.">&2; \
        exit 1; }

    node "$DANMU_LIVE_JS" "$1"
}

get_danmu_live $1
