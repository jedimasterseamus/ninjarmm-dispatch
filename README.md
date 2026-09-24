# ninjarmm-dispatch

Run whatever NinjaOne Remote player version each of your NinjaOne tenants wants, on Linux, automatically.

## The problem

If you work in more than one NinjaOne environment from a Linux machine: one instance gets updated to a new NinjaRemote player version, the other hasn't yet, and only one version of `ninjarmm-ncplayer` can be installed via dpkg at a time. The browser fires a `ninjarmm://` URL, the installed player is the wrong version for that tenant, and you're stuck until the instances line up again.

## How it works

The `ninjarmm://` URL the console hands to the browser already contains the exact player version it expects (`pv=15.37.8880`) and the URL it fetched the player from (`baseUrl=https://resources.ninjarmm.com/development/ninjacontrol/15.37.8880/`). The deb lives at that path with a predictable name, and it's a public download — no tenant token needed.

So instead of registering `ncplayer` directly as the `ninjarmm://` handler, this registers a small script that:

1. reads `pv=` out of the URL,
2. if `~/ninjaremote/<that version>/` doesn't exist, downloads the matching deb from `resources.ninjarmm.com` and unpacks it there (no root, no dpkg install),
3. launches that version's `ncplayer` with the URL.

First connect on a new version costs a few seconds of download. After that it's instant. Each tenant can update whenever it likes and you never touch anything. The deb is fully self-contained: one binary, a desktop file, and a postinst that only runs `xdg-mime default` — nothing else to replicate.

## Install

Run as your normal user, no sudo:

```
curl -fsSLO https://raw.githubusercontent.com/jedimasterseamus/ninjarmm-dispatch/main/install.sh
bash install.sh
```

Or clone the repo and run `bash install.sh`.

Then click Remote on a device in each console. Check `~/ninjaremote/` — you'll see one directory per version plus `dispatch.log`. Old versions can be deleted whenever.

## What's tested / not tested

- Tested: Ubuntu, x86_64, `dpkg-deb` unpack, two tenants on 14.35.8480 and 15.37.8880, Firefox and Chromium-family browsers.
- Untested: the `bsdtar` path for Fedora/Arch/etc., and `aarch64` (NinjaOne publishes aarch64 RPMs so the arch mapping is a guess at the deb name). Reports welcome via Issues.
- This relies on NinjaOne keeping the `pv=` parameter and the `ninjarmm-ncplayer-<ver>_<arch>.deb` filename. If they change either, the script logs the failed URL and falls back to `/opt/NinjaRemote/ncplayer/ncplayer` if you have one installed. Unofficial, obviously.
- The player appears to want a world-writable `/opt/NinjaRemote/logs`. On a box that also runs the NinjaOne agent it's already there. Without the agent, the install script prints the one-liner to create it if you need it.
- No signature verification on the download — but the browser-based install doesn't verify anything either.

## Troubleshooting

- **Sessions still open the old player:** your browser cached the handler. Firefox: `about:preferences` → Applications → `ninjarmm` → set to "Always ask", or delete the entry in `~/.mozilla/firefox/<profile>/handlers.json`. Chrome/Chromium: `chrome://settings/handlers`.
- **`dispatch.log` shows the URL but nothing launches:** run the `exec` line by hand with that URL to see stderr, and check `/opt/NinjaRemote/logs/` for the player's own log.
- **A later `sudo dpkg -i` of a NinjaRemote deb reclaims the handler** (its postinst runs `xdg-mime default`). Re-run `xdg-mime default ninjarmm-dispatch.desktop x-scheme-handler/ninjarmm` to put the dispatcher back. You shouldn't need to install the deb anymore, though.

## Uninstall

```
rm ~/.local/bin/ninjarmm-dispatch ~/.local/share/applications/ninjarmm-dispatch.desktop
rm -rf ~/ninjaremote
xdg-mime default ninjarmm-ncplayer.desktop x-scheme-handler/ninjarmm
```

## License

MIT. Not affiliated with or endorsed by NinjaOne.
