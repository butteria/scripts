# arg: 'search keyword'
function search_fanju() {
    # get cookies.
    cookies=`cat ./cookies`

    # fetch search info.
    search_info=`curl -sG 'http://api.bilibili.com/x/web-interface/search/type' \
        --data-urlencode 'search_type=media_bangumi' \
        --data-urlencode "keyword=$1" \
        -b "SESSDATA=$cookies"`
    message=`echo $search_info | jq -r '.message'`
    [[ "$message" != "0" ]] && { echo "$message"; exit 1; }

    # search nums.
    pages=( `echo $search_info | jq -r '.data | "\(.numResults) \(.numPages)"'` )
    echo "${pages[0]} search results found."
    [[ ${pages[0]} == 0 ]] && { exit 1; }

    # use fzf to choose video.
    choose=$(( `echo $search_info | jq -r '.data.result[].title' | sed 's/<[^>]*>//g' \
        | cat -n | fzf --with-nth 2.. | awk '{print $1}'` - 1 ))
    [[ $choose == -1 ]] && { echo "selection abort by user."; exit 1; }
    
    # use mdid to get more info.
    media_id=( `echo $search_info | jq -r ".data.result[$choose].media_id"` )
    media_info=`curl -sG 'http://api.bilibili.com/pgc/review/user' \
        --data-urlencode "media_id=$media_id" \
        -b "SESSDATA=$cookies"`
    message=`echo $media_info | jq -r '.message'`
    [[ "$message" != "success" ]] && { echo "$message"; exit 1; }

    season_id=`echo $media_info | jq -r '.result.media.season_id'`
    watch_fanju $season_id
}

# arg: season_id.
function watch_fanju() {
    # get season info.
    season_info=`curl -sG 'http://api.bilibili.com/pgc/view/web/season' \
        --data-urlencode "season_id=$1"`
    message=`echo $season_info | jq -r '.message'`
    [[ "$message" != "success" ]] && { echo "$message"; exit 1; }

    # choose video.
    choose=$(( `echo $season_info \
        | jq -r '.result.episodes[] | "\(.share_copy) \(.badge_info.text)"' \
        | cat -n | fzf --with-nth 2.. | awk '{print $1}'` - 1 ))
    [[ $choose == -1 ]] && { echo "selection abort by user."; exit 1; }
    
    # get cid for .danmu and epid for video real url.
    cid=`echo $season_info | jq -r ".result.episodes[$choose].cid"`
    epidbase=`curl -sG 'http://api.bilibili.com/pgc/view/web/season' \
        --data-urlencode "season_id=$1" \
        | jq '.result.episodes[0].id'`
    epid=$( expr $epidbase + $choose )

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
