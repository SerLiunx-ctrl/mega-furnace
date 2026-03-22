# Mega Furnace

A Factorio 2.0 mod that adds two giant late-game electric furnaces for high-throughput smelting.

## Features

- Adds `Mega Furnace` and `High-Energy Mega Furnace`
- Large `15x15` footprint for compact endgame smelting
- Custom black-gold visuals with a more premium look for the high-tier furnace
- Separate technologies and upgrade path
- Recipes can only be crafted in `Assembling Machine 3`
- Mod name and description are localized in Chinese and English

## Balance Overview

### Mega Furnace

- Module slots: `2`
- Crafting speed: `100`
- Energy usage: `18MW`
- Pollution: `60/m`

### High-Energy Mega Furnace

- Module slots: `4`
- Crafting speed: `160`
- Energy usage: `60MW`
- Drain: `2MW`
- Pollution: `120/m`

## Technologies

### Mass Smelting

- Unlocks `Mega Furnace`
- Requires vanilla science packs:
  - `Automation`
  - `Logistic`
  - `Chemical`
  - `Production`
  - `Utility`
- Cost: `1000` of each listed pack

### Mass Smelting 2

- Unlocks `High-Energy Mega Furnace`
- Requires all 7 vanilla science packs
- Cost: `5000` of each pack

## Installation

1. Copy this folder into your Factorio mods directory:
   - `C:\Users\<YourUser>\AppData\Roaming\Factorio\mods\mega_furnace`
2. Make sure the folder contains `info.json` directly at the root.
3. Launch the game and enable the mod.

You can also zip the folder and place the zip file in the `mods` directory.

## Development

- Tested with `Factorio 2.0.76`
- Main prototype file: `prototypes/mega-furnace.lua`

## License

MIT
