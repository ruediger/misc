#!/bin/bash
# Copyright (C) 2011 by Rüdiger Sonderfeld <ruediger@c-plusplus.de>
# License: GNU GPL, version 3 or later; http://www.gnu.org/copyleft/gpl.html
#
# This script queries the minecraft server status and displays the information.
# Thanks to http://www.wiki.vg/Main_Page#Beta

set -e -u

help() {
cat <<EOF
Usage $0 <host> [<port>] -h -v -d <delim>

  -v  be more verbose.
  -h  display help message.
  -d  output everything in one line separated by delim.

Queries the status of the minecraft server on <host> and prints the information. Default port is 25565.
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

MCDELIM=$(echo -ne '\xA7') # string is split by \xA7. '§' in ISO 8859-1.

exec 5<>"/dev/tcp/$HOST/$PORT"
echo -ne '\xFE' >&5
GOT=$(cat <&5) # reply doesn't look like UTF-16BE but spec says so $(iconv -f UTF-16BE <&5)

PREFIX=$(printf '%s' $GOT | cut -b 1)
if [[ "$PREFIX" != "$(echo -ne '\xFF')" ]]; then
    echo "Unkown server reply"
    exit 1
fi

REPLY=$(printf '%s' "$GOT" | cut -b 2-) # strip magic number and size

if [[ "$REPLY" =~ ([[:print:]]*)$MCDELIM([[:digit:]]*)$MCDELIM([[:digit:]]*) ]]; then 

    MOTD="${BASH_REMATCH[1]}"
    USERS="${BASH_REMATCH[2]}"
    SLOTS="${BASH_REMATCH[3]}"

    if [[ "$USEDELIM" == "1" ]]; then
        echo "$HOST$DELIM$PORT$DELIM$MOTD$DELIM$USERS$DELIM$SLOTS"
    else
        echo -e "$HOST:$PORT: $MOTD\n$USERS/$SLOTS players online"
    fi

else
    echo "Unkown server reply format"
    exit 1
fi
