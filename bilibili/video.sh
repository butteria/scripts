# args: bvid
DEAULT_VIDEO_QN="16"
VIDEO_INFO_API="http://api.bilibili.com/x/web-interface/view"
VIDEO_URL_API="http://api.bilibili.com/x/player/playurl"

function choose_vdef {
    local qn_str="$1"
    local qnv_arr="$2"

    choose=$(( $(echo -e "$qn_str" | cat -n | fzf --with-nth 2.. | awk '{print $1}') - 1 )) 
    [[ "$choose" == -1 ]] && { exit 1; }
    # return qn val.
    echo "${qnv_arr[$choose]}"
}

# args: bvid, cid, qn
function fetch_video_info {
    # get video info.
    cookies=$(cat ./cookies)
    video_info=$(curl -sG  "$VIDEO_URL_API"\
        --data-urlencode "bvid=$1" \
        --data-urlencode "cid=$2" \
        --data-urlencode 'fnval=0' \
        --data-urlencode 'fnver=0' \
        --data-urlencode "qn=$3" \
        -b "SESSDATA=$cookies")
    message=$(echo "$video_info" | jq -r '.message')
    [[ "$message" != "0" ]] && { echo "$message" >&2; exit 1; }

    # return video info.
    echo "$video_info"
}

function watch_video {
    local bvid="$1"

    # get cid
    video_info=$(curl -sG "$VIDEO_INFO_API" --data-urlencode "bvid=$bvid")
    message=$(echo "$video_info" | jq -r '.message')
    [[ "$message" != "0" ]] && {
        echo "${BASH_SOURCE[0]}: line ${BASH_LINENO[0]}: $message" >&2;
        exit 1;
    }
    cid=$(echo "$video_info" | jq '.data.cid')

    # fetch video info.
    video_info=$(fetch_video_info "$bvid" "$cid" "$DEAULT_VIDEO_QN")
    [[ $? != 0 ]] && {
        echo "${BASH_SOURCE[0]}: line ${BASH_LINENO[0]}: fetch video info failed." >&2;
        exit 1;
    }

    # check supported video quality.
    qn_str=$(echo "$video_info" | jq '.data.accept_description[]')
    qnv_arr=( $(echo "$video_info" | jq '.data.accept_quality[]') )
    
    # choosen video quality.
    qn=$(choose_vdef "$qn_str" "$qnv_arr")
    [[ $? != 0 ]] && {
        echo "selection aborted.";
        exit 1;
    }
    video_info=$(fetch_video_info "$bvid" "$cid" $qn)
    [[ $? != 0 ]] && {
        echo "${BASH_SOURCE[0]}: line ${BASH_LINENO[0]}: fetch choosen video quality info failed." >&2;
        exit 1;
    }
    url=$(echo "$video_info" | jq -r '.data.durl[0].url') 

    # download danmu.
    #xml=$(download_danmu "$cid")
    #ass=$(xml2ass "$xml")

    mpv "$url"
}
watch_video $1
