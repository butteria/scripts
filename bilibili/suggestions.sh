keyword=$1
default_search_type="video"
# if keyword is empty, search hotspot news
if [ -z "$keyword" ] ; then
    top=10
    items=$( \
        curl -sG "https://api.bilibili.com/x/web-interface/search/square?limit=$top" | \
        jq -r '.data.trending.list[].show_name')
    echo -e "$items"
    exit 0
fi

suggestions=$( \
    echo -e $( \
        curl -sG "https://s.search.bilibili.com/main/suggest" \
             --data-urlencode "term=$keyword" \
             --data-urlencode "type=$default_search_type" \
             --data-urlencode 'main_ver=v1' \
             --data-urlencode 'highlight='
    )
)
items=$(echo "$suggestions" | jq -r '.result.tag[].value')
echo -e "$items"
exit 0
