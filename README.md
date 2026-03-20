# GarminGolfTrainer

A Garmin Connect IQ Watch App for golf training, built with Monkey C.

## Prerequisites

- [Garmin Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) (3.2.0 or later)
- [Visual Studio Code](https://code.visualstudio.com/) with the [Monkey C extension](https://marketplace.visualstudio.com/items?itemName=garmin.monkey-c)

## Project Structure

```
GarminGolfTrainer/
├── manifest.xml                        # App manifest (ID, permissions, target devices)
├── monkey.jungle                       # Build configuration
├── source/
│   ├── GarminGolfTrainerApp.mc         # Application entry point
│   └── GarminGolfTrainerView.mc        # Main watch face view
└── resources/
    ├── drawables/
    │   ├── drawables.xml               # Drawable resource declarations
    │   └── launcher_icon.png           # App launcher icon (70×70 px)
    ├── layouts/
    │   └── layout.xml                  # UI layout definition
    └── strings/
        └── strings.xml                 # Localised strings
```

## Building

1. Open the project folder in VS Code.
2. Use **Monkey C: Build Current Project** from the Command Palette, or run:

```bash
monkeyc -f monkey.jungle -o bin/GarminGolfTrainer.prg -d fenix6 -y developer_key.der
```

## Running in the Simulator

```bash
connectiq &
monkeydo bin/GarminGolfTrainer.prg fenix6
```

## Supported Devices

- Garmin Approach S40, S42, S60, S62
- Garmin Fenix 6 / 6S / 6X (Pro variants)
- Garmin Fenix 7 / 7S / 7X
- Garmin Forerunner 945, 955
- Garmin Vivoactive 4 / 4S