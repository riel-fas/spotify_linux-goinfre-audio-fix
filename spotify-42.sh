#!/usr/bin/env bash
# spotify-42.sh — install Spotify (Flatpak) on goinfre + PulseAudio/headphones fix
# Based on https://github.com/riel-fas/spotify_fix_flatapak (no sudo needed)
set -euo pipefail

cat <<'BANNER'
             ___    _______ _________ ______   ______  
|\     /|   /   )  (  ____ \\__   __// ___  \ (  __  \ 
| )   ( |  / /) |  | (    \/   ) (   \/   \  \| (  \  )
| | _ | | / (_) (_ | (_____    | |      ___) /| |   ) |
| |( )| |(____   _)(_____  )   | |     (___ ( | |   | |
| || || |     ) (        ) |   | |         ) \| |   ) |
| () () |     | |  /\____) |   | |   /\___/  /| (__/  )
(_______)     (_)  \_______)   )_(   \______/ (______/
BANNER
echo

APP=com.spotify.Client
GOINFRE="${GOINFRE:-/goinfre/$USER}"

die() { printf '%s\n' "$*" >&2; exit 1; }

# 0. Checks
command -v flatpak >/dev/null || die "Flatpak is not available on this session."
[[ -d $GOINFRE ]] || mkdir -p "$GOINFRE" 2>/dev/null || die "Cannot use $GOINFRE (set GOINFRE=/path and retry)."

# 1. Redirect heavy dirs to goinfre via symlinks (home quota is small)
#    - ~/.local/share/flatpak : Flatpak user installation (runtimes + Spotify)
#    - ~/.var/app/$APP        : Spotify config, cache, offline songs
redirect() {
    local target=$1 link=$2
    mkdir -p "$target" "$(dirname "$link")"
    if [[ -L $link ]]; then
        [[ $(readlink "$link") == "$target" ]] && return 0
        rm "$link"
    elif [[ -e $link ]]; then
        # move existing data to goinfre, then link
        cp -a "$link"/. "$target"/ 2>/dev/null || true
        rm -rf "$link"
    fi
    ln -s "$target" "$link"
}
redirect "$GOINFRE/flatpak"        "$HOME/.local/share/flatpak"
redirect "$GOINFRE/spotify-data"   "$HOME/.var/app/$APP"

# 2. Install Spotify in the user installation (no sudo)
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
if ! flatpak info --user "$APP" >/dev/null 2>&1; then
    flatpak install --user -y flathub "$APP"
fi

# 3. Headphones / no-sound fix: force PulseAudio backend
command -v pactl >/dev/null || die "pactl not found."
pactl info >/dev/null || die "Audio server unavailable. Log into your desktop session and retry."

flatpak run --command=sh "$APP" -c '
set -eu
config_file="$XDG_CONFIG_HOME/spotify-flags.conf"
mkdir -p "$XDG_CONFIG_HOME"
if ! grep -qxF -- "--audio-api=pulseaudio" "$config_file" 2>/dev/null; then
    [ -f "$config_file" ] && cp -p "$config_file" "$config_file.backup-$(date +%Y%m%d-%H%M%S)"
    printf "\n%s\n" "--audio-api=pulseaudio" >> "$config_file"
fi
'

# 4. (Re)start Spotify with the fix
if flatpak ps --columns=application | grep -qxF "$APP"; then
    flatpak kill "$APP"
fi
log_dir="${XDG_CACHE_HOME:-$HOME/.cache}/spotify-fix"
mkdir -p "$log_dir"
nohup flatpak run --command=sh "$APP" -c '
exec env PULSE_PROP_application.icon_name=com.spotify.Client LD_PRELOAD=/app/lib/spotify-preload.so /app/extra/bin/spotify --audio-api=pulseaudio
' > "$log_dir/launch.log" 2>&1 < /dev/null &

printf 'Done. Spotify installed in %s and starting (press Play).\nLog: %s/launch.log\n' "$GOINFRE" "$log_dir"
