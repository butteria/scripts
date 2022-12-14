#! /bin/sh

SUGGESTIONS_DEFAULT_API="https://api.bilibili.com/x/web-interface/search/"
SUGGESTIONS_HOTSPOT_API="https://api.bilibili.com/x/web-interface/search/square"
SUGGESTIONS_KEYWORD_API="https://s.search.bilibili.com/main/suggest"
function curl_api()
{
    curl_cmd="curl -sG $1 -b \"SESSDATA=$(cat ./cookies)\" "
    for i in "${@:3}"; do
        curl_cmd="$curl_cmd --data-urlencode \"$i\" "
    done

    result=$(eval $curl_cmd)
    message="$(echo "$result" | jq '.message')"
    if [[ "$message" == "0" ]] ; then
        echo "$0: line ${LINENO[0]}: $message." >&2
        exit 1
    fi
    echo "$result" | jq -r "$2"
}
