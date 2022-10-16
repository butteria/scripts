function perr {
    echo "func: ${FUNCNAME[0]} at line ${BASH_LINENO[0]}: $1" >&2;
    exit 1
}
