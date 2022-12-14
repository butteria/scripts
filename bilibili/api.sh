function FETCH_FROM_API() {
    #param:  API, JQ_PARSE_EXPR, [EXTRA_ARGS], args...
    cmd="curl -H "charset=UTF-8" --data-urlencode utf8 -sG $1 "
    [[ "$3" != "NULL" ]] && {
        cmd="$cmd $3"
    }
    for i in "${@:4}"; do
        cmd="$cmd --data-urlencode \"$i\" "
    done

    result="$(eval $cmd)"
    message="$(printf "%s" "$result" | jq '.message')"
    [[ "$message" == "0" ]] && {
        echo "$0: line ${LINENO[0]}: $message." >&2;
        exit 1
    } || {
        printf "%s" "$(printf "%s" "$result" | jq -r "$2")"
    }
}
