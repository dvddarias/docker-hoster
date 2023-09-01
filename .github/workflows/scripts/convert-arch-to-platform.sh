#!/usr/bin/env bash

qemu_platforms=""

for p in $(echo "$1" | tr ',' '\n'); do
  v=""
  case "$p" in
    "linux/arm64")
      v="$p/v8" ;;
    # Skip platforms we don't need
    "linux/386") ;;
    *)
      v="$p" ;;
  esac

  if [ -z "$qemu_platforms" ]; then
    qemu_platforms="$v"
  else
    qemu_platforms="$qemu_platforms,$v"
  fi
done

echo "$qemu_platforms"
