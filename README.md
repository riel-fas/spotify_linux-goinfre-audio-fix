# spotify-42

Install Spotify (Flatpak) on a 42 school Linux session, store it on `goinfre`, and fix the no-sound / headphones problem. No sudo needed.

Based on [riel-fas/spotify_fix_flatapak](https://github.com/riel-fas/spotify_fix_flatapak).

## What it does

1. Moves Flatpak and Spotify data to `/goinfre/$USER` using symlinks, so your home quota stays free.
2. Installs `com.spotify.Client` from Flathub (user install).
3. Forces the PulseAudio backend (`--audio-api=pulseaudio`) and restarts Spotify.

## Requirements

- Linux with `bash`, `flatpak` and `pactl`
- A logged-in desktop session with working audio

## Usage

```bash
bash spotify-42.sh
```

Custom goinfre path:

```bash
GOINFRE=/your/path bash spotify-42.sh
```

## Notes

- `goinfre` can be wiped. If Spotify disappears, rerun the script; it skips what is already done.
- Launch log: `~/.cache/spotify-fix/launch.log`
- To undo the audio fix, remove the `--audio-api=pulseaudio` line from `~/.var/app/com.spotify.Client/config/spotify-flags.conf` and restart Spotify.
