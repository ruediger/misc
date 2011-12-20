#!/bin/bash

set -e -u

help() {
    cat <<EOF
Usage $0 <host> [<port>] -h -v -d <delim>

-v be more verbose
-h display help
-d output everything in one line separated by delim

Default port is 25565.
EOF
    exit 1
}

while getopts "::hvd:" opt; do
    case $opt in
        d)
            DELIM="${OPTARG:- }"
            USEDELIM=1
            ;;
        h)
            help
            ;;
        v)
            VERBOSE=1
            ;;
        \?)
            echo "Unkown option '$OPTARG'!"
            help
            ;;
    esac
done

USEDELIM="${USEDELIM:-0}"
VERBOSE="${VERBOSE:-0}"

shift $((OPTIND-1))
if [ "$#" == 0 ]; then
    echo "No hostname given!"
    help
    exit 1
fi
HOST=$1
PORT=${2:-25565}

if [[ "$VERBOSE" == "1" ]]; then
    echo "Querying $HOST:$PORT"
fi

exec 5<>"/dev/tcp/$HOST/$PORT"
echo -ne '\xFE' >&5
REPLY=`cut -b 4- <&5`

MCDELIM=`echo -ne '\xA7'`

MOTD=`echo -n "$REPLY" | cut -d "$MCDELIM" -f 1`
USERS=`echo -n "$REPLY" | cut -d "$MCDELIM" -f 2`
SLOTS=`echo -n "$REPLY" | cut -d "$MCDELIM" -f 3`

if [[ "$USEDELIM" == "1" ]]; then
    echo "$HOST$DELIM$PORT$DELIM$MOTD$DELIM$USERS$DELIM$SLOTS"
else
    echo -e "$HOST:$PORT: $MOTD\n$USERS/$SLOTS players online"
fi
