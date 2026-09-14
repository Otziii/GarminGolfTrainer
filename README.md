# GarminGolfTrainer

A Garmin Connect IQ watch app for golf range training, built with Monkey C.

## Prerequisites

- [Garmin Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) 3.2.0 or later
  (developed against 9.1.0)
- [Visual Studio Code](https://code.visualstudio.com/) with the
  [Monkey C extension](https://marketplace.visualstudio.com/items?itemName=garmin.monkey-c)
- A developer key, expected at `../developer_key` (kept outside the repo on
  purpose — it signs your builds and must not be committed)
- For sideloading from macOS: `brew install libmtp`

## Project Structure

```
GarminGolfTrainer/
├── manifest.xml                # App id, permissions, target device
├── monkey.jungle               # Build configuration
├── source/
│   ├── GarminGolfTrainerApp.mc # Application entry point
│   ├── HomeMenu.mc             # Root menu
│   ├── RangeActivity.mc        # Recording session + FIT activity
│   ├── ShotWizard.mc           # Per-shot entry flow
│   ├── ShotQualityMenu.mc      # Strike quality picker
│   ├── DistancePicker.mc       # Distance entry
│   ├── ShotHistory.mc          # Stored shot log
│   ├── StatsView.mc            # Aggregate statistics
│   ├── ClubGraphView.mc        # Per-club distance graph
│   ├── SessionSummary.mc       # End-of-session recap
│   ├── SettingsMenu.mc         # App settings
│   └── ConfirmationView.mc     # Shared confirmation prompt
├── resources/
│   ├── drawables/              # drawables.xml + launcher_icon.png
│   ├── layouts/layout.xml      # UI layout definitions
│   ├── strings/strings.xml     # Localised strings (eng)
│   └── fitfields.xml           # FitContributor field definitions
└── tools/
    ├── install.sh              # Build + sideload to a connected watch
    ├── mtpsend.c               # Minimal MTP pusher (see Sideloading)
    └── Makefile                # Builds tools/mtpsend
```

## Supported Devices

`manifest.xml` targets exactly one product: **fenix 8 Solar 47 mm**
(`fenix8solar47mm`, part number `006-B4532-00`).

Adding another device means adding an `<iq:product>` entry and rebuilding — the
`.prg` is compiled per device. Note that the fenix 8 Solar 51 mm
(`fenix8solar51mm`) and the AMOLED fenix 8 47 mm (`fenix847mm`) are *separate*
targets, despite the similar names.

The launcher icon for this device is 40×40 px; `launcher_icon.png` is currently
60×60 and gets scaled down at runtime.

## Building

```bash
tools/install.sh --build-only
```

Or directly, if you prefer:

```bash
SDK="$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b"
"$SDK/bin/monkeyc" -f monkey.jungle -o bin/GarminGolfTrainer-release.prg \
    -d fenix8solar47mm -y ../developer_key -r
```

Drop `-r` for a debug build. Release builds are what you want on the watch;
debug builds are larger and slower.

## Running in the Simulator

```bash
SDK="$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b"
"$SDK/bin/connectiq" &
"$SDK/bin/monkeydo" bin/GarminGolfTrainer-release.prg fenix8solar47mm
```

## Sideloading to a Watch

```bash
tools/install.sh
```

That builds a signed release `.prg`, closes anything holding the USB interface,
pushes the app to `GARMIN/Apps`, and verifies it arrived. Then unplug the watch
and press **START** — "Golf Trainer" is in the activity list. First launch
prompts for the sensor and FIT permissions declared in `manifest.xml`.

The `.prg` disappears from `GARMIN/Apps` on the next connect. The watch has
moved it into internal app storage; the install is fine.

### Why not just drag the file across?

Three things make this harder than it should be on macOS, and all three are
handled by `install.sh`:

1. **The fenix 8 is MTP-only** — it has no USB mass-storage mode, and macOS has
   no native MTP support. The watch never appears in Finder. It is visible in
   `ioreg` as Garmin vendor `0x091E`.
2. **Android File Transfer steals the device.** Its background agent claims any
   MTP device the instant it is plugged in and holds the USB interface
   exclusively, so libmtp fails with `libusb_claim_interface() = -3`. Garmin
   Express behaves the same way. Both must be quit, menu-bar items included.
3. **`mtp-sendfile` cannot reach the folder.** libmtp resolves destination
   paths by walking a full recursive listing, and this watch fails
   `get_all_metadata_fast()`. So `/GARMIN/Apps` never resolves and every send
   dies with "Parent folder could not be found". `tools/mtpsend` skips the path
   parser and uses folder IDs via `LIBMTP_Get_Files_And_Folders`, which the
   watch answers correctly. It also needs an *uncached* device handle, since the
   cached one rejects folder-scoped listings outright.

`tools/mtpsend` is usable on its own for poking at the watch filesystem:

```bash
tools/mtpsend resolve GARMIN/Apps          # folder id for a path
tools/mtpsend list    GARMIN/Apps          # list a folder
tools/mtpsend send    app.prg GARMIN/Apps GarminGolfTrainer.prg
tools/mtpsend get     16779627 ./copy.prg  # pull a file back off the watch
```

`send` replaces any same-named file first; MTP otherwise allows duplicates in
one folder, which piles up stale copies across reinstalls.

## Troubleshooting

An app that crashes on the watch leaves a log in `GARMIN/Apps/LOGS`, written as
`CIQ_LOG.BAK` (rotating to `CIQ_LOG2.BAK`) on this firmware:

```bash
tools/mtpsend list GARMIN/Apps/LOGS
tools/mtpsend get <objectid> ./CIQ_LOG.BAK
```

Addresses in that log map back to source lines via the
`bin/GarminGolfTrainer-release.prg.debug.xml` produced alongside the build.

Watch apps on this device have a 768 KB memory ceiling.

Beware that `GARMIN/GarminDevice.xml` (useful for confirming the exact part
number and firmware) also contains your map unlock codes — don't paste it
anywhere public.
