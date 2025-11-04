#!/bin/sh
usage="
    $(basename $0) <zone-file-path> <url> [genrpz.py arguments]"
test -n "$1" || { echo "error: missing zone-file-path
usage: $usage" && exit 1; }
test ! -f "$1" -o -w "$1" || { echo "cannot write zone-file to \"$1\"" && exit 2; }
test -n "$2" || { echo "error: missing url
usage: $usage" && exit 3; }
zonefile=$1 && url=$2 && shift 2 &&
newfile=$(mktemp) && trap "rm -f $newfile" EXIT &&
curl -fLso "$newfile" "$url" &&
if test $? -eq 22; then echo "error getting $url"; exit 4; fi &&
if test -n "$*"; then
        newzonefile=$(mktemp) && trap "rm -f $newfile $newzonefile" EXIT &&
        python3 "${GENRPZ_PY}" -f "$newfile" -F "$newzonefile" "$@" &&
        newfile="$newzonefile" || { echo "error running genrpz.py" && exit 5; }
fi &&
if test "$(tail -c 1 "$newfile")" != '\n'; then echo >> "$newfile"; fi &&
if test -f "$zonefile"; then mv -f "$zonefile" "${zonefile}.bak"; fi &&
case $(id -u) in
        0) install -m ${RPZ_PERMS} -g "${RPZ_USERGROUP}" "$newfile" "$zonefile" ;;
        *) cp -f "$newfile" "$zonefile" ;;
esac