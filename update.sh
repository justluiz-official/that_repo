#!/usr/bin/env bash
# Refreshes the local mirror of Free-TV/IPTV and rebuilds the two mixed
# playlists from it. Safe to run as often as you like — re-run it any time
# you want fresher channels/URLs.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$ROOT/source"
OUT_DIR="$ROOT/playlists"
PLAYLISTS_DIR="$SOURCE_DIR/playlists"
REPO_URL="https://github.com/Free-TV/IPTV.git"
BRANCH="master"

mkdir -p "$OUT_DIR"

if [[ ! -d "$SOURCE_DIR/.git" ]]; then
  echo "First run: cloning Free-TV/IPTV..."
  git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$SOURCE_DIR"
else
  echo "Fetching latest changes from Free-TV/IPTV ($BRANCH)..."
  git -C "$SOURCE_DIR" fetch --depth 1 origin "$BRANCH"
  # Free-TV/IPTV's own GitHub Action regenerates playlist_*.m3u8 on every
  # push and force-pushes master with the new commit (see its
  # update_playlist.yml), so master's history gets rewritten, not just
  # extended. A plain "git pull" would fail here with a non-fast-forward
  # error. This clone only ever mirrors upstream — nothing is committed to
  # it locally — so resetting the local branch to match origin exactly is
  # safe and is the correct way to track a history that gets rewritten.
  git -C "$SOURCE_DIR" reset --hard "origin/$BRANCH"
fi

# Builds one mixed playlist from several of Free-TV/IPTV's per-country
# .m3u8 files. Every file there starts with one #EXTM3U header line (the
# shared EPG source list) followed by #EXTINF/URL pairs. Concatenating the
# files as-is would repeat that header once per country, which some IPTV
# players reject — so we keep a single header and append only the channel
# entries from each source file after it.
build_mix() {
  local out_file="$1"; shift
  local countries=("$@")

  for country in "${countries[@]}"; do
    local src="$PLAYLISTS_DIR/playlist_${country}.m3u8"
    if [[ ! -f "$src" ]]; then
      echo "ERROR: expected file not found: $src" >&2
      echo "Free-TV/IPTV may have renamed or removed this country's playlist — check https://github.com/Free-TV/IPTV/tree/master/playlists" >&2
      return 1
    fi
  done

  local ref_header
  ref_header="$(head -n 1 "$PLAYLISTS_DIR/playlist_${countries[0]}.m3u8")"
  for country in "${countries[@]}"; do
    local header
    header="$(head -n 1 "$PLAYLISTS_DIR/playlist_${country}.m3u8")"
    if [[ "$header" != "$ref_header" ]]; then
      echo "WARNING: ${country}'s #EXTM3U header differs from ${countries[0]}'s — using ${countries[0]}'s header. EPG data may be incomplete for ${country}." >&2
    fi
  done

  {
    printf '%s\n' "$ref_header"
    for country in "${countries[@]}"; do
      tail -n +2 "$PLAYLISTS_DIR/playlist_${country}.m3u8"
    done
  } > "$out_file"

  echo "Wrote $(basename "$out_file") ($(grep -c '^#EXTINF' "$out_file") channels: ${countries[*]})"
}

build_mix "$OUT_DIR/mix-br-pt-it.m3u8" brazil portugal italy
build_mix "$OUT_DIR/mix-pt-it-ua-uk.m3u8" portugal italy ukraine uk

echo "Done. Playlists are in: $OUT_DIR"
