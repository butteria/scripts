#! /bin/sh

# map args and return non-optional args.
function opts2map {
    local -n REF_ARGS="$1"
    local -n REF_MAP="$2"
    for ((i = 0; i < ${#REF_ARGS[@]}; i++)); do
        local key="${REF_ARGS[$i]}"
        local val=true

        # check if it is key.
        [[ "$key" =~ ^(\-.*) ]] || { echo "$key"; continue; }
        if [[ "$key" == *=* ]]; then
            <<<"$key" \
                IFS='=' read key val
        fi
        # delete prefix '--' or '-'.
        REF_MAP["${key##*-}"]="$val"
    done
}
