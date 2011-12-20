#!/bin/bash
# Copyright (C) 2011 by Rüdiger Sonderfeld <ruediger@c-plusplus.de>
# License: GNU GPL, version 3 or later; http://www.gnu.org/copyleft/gpl.html
#
# This script queries the minecraft server status and displays the information.
# Thanks to http://www.wiki.vg/Main_Page#Beta

set -e -u

help() {
    cat >&2 <<EOF
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
            echo "Unkown option '$OPTARG'!" >&2
            help
            ;;
    esac    
done

USEDELIM="${USEDELIM:-0}"
VERBOSE="${VERBOSE:-0}"

shift $((OPTIND-1))
if [ "$#" == 0 ]; then
    echo "No hostname given!" >&2
    help
    exit 1
fi
HOST=$1
PORT=${2:-25565}

if [[ "$VERBOSE" == "1" ]]; then
    echo "Querying $HOST:$PORT"
fi

MCDELIM='§'

# Connect to server and send 0xFE to request status
exec 5<>"/dev/tcp/$HOST/$PORT"
echo -ne '\xFE' >&5
# strip first four bytes (magic number, length), delete newline added by cut, and convert from utf16-be to locale
REPLY=$(cut -b 4- <&5 | tr -d '\n' | iconv -f UTF-16BE -c)

#PREFIX=$(printf '%s' $GOT | cut -b 1)
#if [[ "$PREFIX" != "$(echo -ne '\xFF')" ]]; then
#    echo "Unkown server reply" >&2
#    exit 1
#fi

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
    echo "Unkown server reply format" >&2
    exit 1
fi
