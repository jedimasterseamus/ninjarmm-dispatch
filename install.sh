#!/bin/bash
# ninjarmm-dispatch installer
# Registers a ninjarmm:// handler that fetches and runs whichever NinjaOne Remote
# player version the console asks for. Run as your normal user. No sudo.
set -e
mkdir -p "$HOME/.local/bin" "$HOME/.local/share/applications" "$HOME/ninjaremote"

cat > "$HOME/.local/bin/ninjarmm-dispatch" <<'EOF'
#!/bin/bash
# Launches the NinjaOne Remote player version that the console asked for.
url="$1"
cache="$HOME/ninjaremote"
log="$cache/dispatch.log"
fallback="/opt/NinjaRemote/ncplayer/ncplayer"
mkdir -p "$cache"
echo "$(date '+%F %T') $url" >> "$log"

fail() {
  echo "$(date '+%F %T') $1" >> "$log"
  if command -v notify-send >/dev/null
  then
    notify-send "NinjaOne Remote" "$1"
  fi
  if [ -x "$fallback" ]
  then
    exec "$fallback" "$url"
  fi
  exit 1
}

case "$(uname -m)" in
  x86_64)
    arch="amd64"
    ;;
  aarch64)
    arch="arm64"
    ;;
  *)
    fail "unsupported architecture: $(uname -m)"
    ;;
esac

pv="$(printf '%s' "$url" | sed -n 's/.*[?&]pv=\([0-9.]*\).*/\1/p')"
if [ -z "$pv" ]
then
  fail "no pv= parameter in URL"
fi

bin="$cache/$pv/opt/NinjaRemote/ncplayer/ncplayer"
if [ ! -x "$bin" ]
then
  deb="$cache/ninjarmm-ncplayer-${pv}_${arch}.deb"
  src="https://resources.ninjarmm.com/development/ninjacontrol/${pv}/ninjarmm-ncplayer-${pv}_${arch}.deb"
  if ! curl -fsSL -o "$deb" "$src"
  then
    fail "download failed: $src"
  fi
  mkdir -p "$cache/$pv"
  if command -v dpkg-deb >/dev/null
  then
    dpkg-deb -x "$deb" "$cache/$pv"
  elif command -v bsdtar >/dev/null
  then
    bsdtar -xOf "$deb" 'data.tar*' | bsdtar -xf - -C "$cache/$pv"
  else
    fail "need dpkg-deb or bsdtar to unpack $deb"
  fi
fi
exec "$bin" "$url"
EOF
chmod +x "$HOME/.local/bin/ninjarmm-dispatch"

cat > "$HOME/.local/share/applications/ninjarmm-dispatch.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=NinjaOne Remote Dispatcher
Exec=$HOME/.local/bin/ninjarmm-dispatch %u
StartupNotify=false
MimeType=x-scheme-handler/ninjarmm;
NoDisplay=true
EOF

update-desktop-database "$HOME/.local/share/applications"
xdg-mime default ninjarmm-dispatch.desktop x-scheme-handler/ninjarmm
echo "ninjarmm:// handler is now: $(xdg-mime query default x-scheme-handler/ninjarmm)"
if [ ! -d /opt/NinjaRemote/logs ]
then
  echo "Note: /opt/NinjaRemote/logs does not exist. If sessions fail to launch, try:"
  echo "  sudo mkdir -p -m 777 /opt/NinjaRemote/logs"
fi
