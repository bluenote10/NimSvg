#!/bin/bash

cd `dirname $0`

clear

while true; do
  nim -r c src/svg.nim

  change=$(inotifywait -r -e close_write,moved_to,create,modify . \
    --exclude 'src/main$|bin/.*|.*\.log|nimcache|.changes|.git/.*|#.*' \
    2> /dev/null)

  # very short sleep to avoid "text file busy"
  sleep 0.01

  clear
  echo "changed [`date +%T`]: $change"
done