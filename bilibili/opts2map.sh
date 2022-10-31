#! /bin/sh

function opts2map {
    local -n REF_ARGS="$1"
    local -n REF_MAP="$2"
    local k=0
    for ((i = 0; i < ${#REF_ARGS[@]}; i++)); do
        local key="${REF_ARGS[$i]}"
        local val=true

        # check if it is key.
        [[ "$key" =~ ^(\-.*) ]] || {
            map[$k]="$key";
            (($k+1));
            continue;
        }
        if [[ "$key" == *=* ]]; then
            <<<"$key" \
                IFS='=' read key val
        fi
        # delete prefix '--' or '-'.
        key="$(echo $key | sed -e 's/^-*//')"
        REF_MAP["${key}"]="$val"
    done
}
