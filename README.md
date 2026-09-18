# justluiz-iptv

Local IPTV playlists mixed from [Free-TV/IPTV](https://github.com/Free-TV/IPTV), a public repo of free-to-air channel lists by country.

This folder is local only — there's no repo of your own to maintain, host or push to. `source/` is just a working copy of the upstream repo that gets refreshed in place.

## What's here

- `source/` — a local copy of the Free-TV/IPTV repo. Refreshed automatically by `update.sh`; never edit anything inside it by hand, it gets overwritten.
- `playlists/mix-br-pt-it.m3u8` — Brazil + Portugal + Italy channels combined.
- `playlists/mix-pt-it-ua-uk.m3u8` — Portugal + Italy + Ukraine + UK channels combined.
- `update.sh` — refreshes `source/` from upstream and rebuilds both playlists above.

## Refreshing the playlists

Whenever you want the latest channels/URLs from the main repo, open Terminal and run:

```
cd ~/sites/_Personal/justluiz-iptv && ./update.sh
```

It prints how many channels ended up in each playlist. Takes a few seconds.

## Using the playlists

Point any IPTV player (VLC, IPTV Smarters, TiviMate, etc.) at the local file path:

```
/Users/jc/sites/_Personal/justluiz-iptv/playlists/mix-br-pt-it.m3u8
/Users/jc/sites/_Personal/justluiz-iptv/playlists/mix-pt-it-ua-uk.m3u8
```

Most players have an "Add playlist from file/URL" option — use the file path, not a web address.

## Changing which countries are mixed

Open `update.sh` in a text editor and find these two lines near the bottom:

```
build_mix "$OUT_DIR/mix-br-pt-it.m3u8" brazil portugal italy
build_mix "$OUT_DIR/mix-pt-it-ua-uk.m3u8" portugal italy ukraine uk
```

Each line is one playlist: the output filename, then the list of countries to combine. Country names must match a filename under `source/playlists/` (e.g. `brazil` for `playlist_brazil.m3u8`) — check that folder for the exact spelling of any country you want to add. Save the file, then run `./update.sh` again.

## Why a "reset" instead of a normal git pull

Free-TV/IPTV's own automation rewrites and force-pushes its `master` branch every time it regenerates the playlist files. `update.sh` accounts for this by resetting the local `source/` copy to match upstream exactly on every refresh, rather than merging — so it keeps working instead of eventually failing with a "diverged history" error. This only ever affects the `source/` copy, never your two playlist files.
