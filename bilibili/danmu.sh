#! /bin/sh
# API: http://api.bilibili.com/x/v1/dm/list.so
curl -sG 'http://api.bilibili.com/x/v1/dm/list.so' \
    --data-urlencode "oid=$1" \
    --compressed -o "$2"
[[ $? != 0 ]] && { echo "curl failed."; exit 1; }
