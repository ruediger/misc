#!/bin/bash

function die() {
  echo "Die! $@"
  exit 1
}

declare -a list
list=("$@")

if [[ -z "${list[@]}" ]]; then
    xclip=$(xclip -o)
    if [[ "$xclip" =~ youtube.com ]]; then
      read -p "Use URL '$xclip' [Y/n]? " usep
      if [[ "$usep" != "n" && "$usep" != "N" ]]; then
        list=("$xclip")
      fi
    fi

    if [[ -z "${list[@]}" ]]; then
      read -p "URL? " url
      list=("$url")
    fi
fi

echo "Downloading ${list[@]}"

ffmpeg=avconv

tmp=$(tempfile) || die "Tmpfile"
trap "rm -f -- '$tmp'" EXIT

youtube-dl --extract-audio -t "${list[@]}" | tee "$tmp"

IFS=$'\n'
declare -a out
out=($(<"$tmp"))

rm -f -- "$tmp"
trap - EXIT

if [[ ${out[-1]} =~ Destination:\ (.*) ]]; then
  filename=${BASH_REMATCH[1]}
  echo $filename
  if [[ $filename =~ (.*)\.aac ]]; then
      to_wav=${filename/%.aac/.wav}
      to_opus=${filename/%.aac/.opus}
      $ffmpeg -i "$filename" "$to_wav" && opusenc --music "$to_wav" "$to_opus" && echo $to_opus
      rm -f -- "$to_wav" "$filename"
  else
      echo $filename
  fi
fi
