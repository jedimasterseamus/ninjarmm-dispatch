# ninjarmm-dispatch

I work in two different NinjaOne environments from a Linux laptop. One of them updated NinjaRemote to version 15, the other one was still on 14, and since only one `ninjarmm-ncplayer` deb can be installed at a time I could only connect to one of them. Not a great spot to be in when you have work to do in both. This fixes that, and it keeps fixing it every time either environment updates.

## How it works

When you hit Remote in the console, the browser fires a `ninjarmm://` URL at whatever is registered to handle it. That URL already has everything in it: `pv=15.37.8880` is the exact player version the console wants, and `baseUrl=https://resources.ninjarmm.com/development/ninjacontrol/15.37.8880/` is where it got the player from. The deb sits at that path under a predictable name and downloads without any tenant token.

So instead of pointing the handler at `ncplayer` directly, this installs a small script as the handler that:

1. pulls the version out of the URL
2. if it hasn't seen that version before, downloads the deb and unpacks it into `~/ninjaremote/<version>/` (no root, no dpkg)
3. runs that version's `ncplayer` with the URL

The first connect on a new version takes a few extra seconds for the download. After that it's instant. Either environment can update whenever it wants and you don't have to touch anything. The deb is one binary, a desktop file, and a postinst that only runs `xdg-mime default`, so there's nothing else worth replicating.

## Install

Run as yourself, no sudo:

```
curl -fsSLO https://raw.githubusercontent.com/jedimasterseamus/ninjarmm-dispatch/main/install.sh
bash install.sh
```

Or clone this and run `bash install.sh`.

Then hit Remote on a device in each console. `~/ninjaremote/` will end up with one folder per version plus a `dispatch.log`. Delete old versions whenever you want.

## What I've tested

Ubuntu on x86_64, unpacking with `dpkg-deb`, two tenants on 14.35.8480 and 15.37.8880, Firefox and Chromium.

What I haven't: the `bsdtar` path for Fedora/Arch/whatever else, and aarch64. NinjaOne publishes aarch64 RPMs so I'm guessing at the deb name for that. If you try either one and it works or doesn't, open an issue.

A few other things worth knowing:

- This depends on NinjaOne keeping the `pv=` parameter and the `ninjarmm-ncplayer-<version>_<arch>.deb` filename. If they change either one, the script logs the URL it tried and falls back to `/opt/NinjaRemote/ncplayer/ncplayer` if you have that installed. It's not official and NinjaOne could break it whenever they want.
- The player wants to write to `/opt/NinjaRemote/logs`. If the NinjaOne agent is on the machine that folder's already there. If not, the installer prints the one-liner to create it.
- Nothing verifies the download. The browser install doesn't either.

## If it doesn't work

- Still launching the old player: the browser cached the handler. Firefox: about:preferences, Applications, find `ninjarmm` and set it to Always ask (or delete it out of `handlers.json` in your profile folder). Chrome: `chrome://settings/handlers`.
- The log shows the URL but nothing opens: run the last `exec` line from the script by hand with that URL and see what it complains about. The player also writes its own log in `/opt/NinjaRemote/logs/`.
- If you `sudo dpkg -i` a NinjaRemote deb later, its postinst takes the handler back. `xdg-mime default ninjarmm-dispatch.desktop x-scheme-handler/ninjarmm` gives it back to the script. You shouldn't need the deb anymore though.

## Uninstall

```
rm ~/.local/bin/ninjarmm-dispatch ~/.local/share/applications/ninjarmm-dispatch.desktop
rm -rf ~/ninjaremote
xdg-mime default ninjarmm-ncplayer.desktop x-scheme-handler/ninjarmm
```

MIT licensed. Not affiliated with NinjaOne.
