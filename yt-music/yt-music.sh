#!/usr/bin/env bash

YDL=youtube-dl

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

$YDL --extract-audio --prefer-free-formats  --add-metadata -t "${list[@]}" | tee "$tmp"

IFS=$'\n'
declare -a out
out=($(<"$tmp"))

rm -f -- "$tmp"
trap - EXIT

# Maybe need to add $'\n' to beginning/end of $out for first/last line.
#destination_re=$'\n\[avconv\]\ Destination:\ (.*)\n'
destination_re=$'\n\[download\]\ Destination:\ ([^\n]*)\n'
if [[ "${out[*]}" =~ $destination_re ]]; then
  filename=${BASH_REMATCH[1]}
  echo "Filename: $filename"
  if [[ $filename =~ (.*)\.(aac|m4a) ]]; then
      to_wav=${filename%.${BASH_REMATCH[2]}}.wav
      to_opus=${to_wav%.wav}.opus
      $ffmpeg -i "$filename" "$to_wav" && opusenc "$to_wav" "$to_opus" && echo $to_opus
      rm -f -- "$to_wav" "$filename"
  else
      echo $filename
  fi
fi
