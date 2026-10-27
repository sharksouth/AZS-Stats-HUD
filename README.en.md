# AZS Stats HUD

[简体中文](README.md) | **English**

A standalone stats panel for Azeroth Survivors that displays character and adventure stats directly on your screen.

## Features

- Reads and automatically updates stats provided by the game.
- Drag the panel to move it, or drag its bottom-right corner to adjust width and height independently without changing text size. The panel cannot be made shorter than its contents.
- Saves position, scale, visibility, and lock settings.
- Lock the panel to allow mouse clicks to pass through it.
- Defaults to Chinese; switch to English manually or try automatic client-locale detection.

## Installation

Copy the `AZSStatsHUD` folder into `benilla-config/AddOns/` in your game directory. Make sure `AZSStatsHUD.toc` is inside the folder, then re-enter the game and enable the addon in the addon list.

## Commands

| Command | Action |
| --- | --- |
| `/ast` | Show or hide the panel |
| `/ast lock` / `/ast unlock` | Lock or unlock the panel |
| `/ast scale 0.8` | Set overall scale (0.6–1.6) |
| `/ast reset` | Restore the default position and size |
| `/ast debug` | Check whether data has been received |
| `/ast lang auto` / `zh` / `en` | Select automatic, Chinese, or English; for example, `/ast lang en` |

Automatic mode uses the locale returned by the client. If it does not match the game language setting, use the command above to choose a language. Unsupported locales fall back to English.

## Credits and sources

The panel independently reads the game's `AZS` stats messages and does not depend on SurvivorsDragonUi. The game and [SurvivorsDragonUi](https://github.com/migwynkriid13/SurvivorsDragonUi) were consulted for stat display and meanings; this repository does not include its code or images. The interface references textures provided by the game at runtime and does not distribute game assets.

This is a community addon and is not officially affiliated with the game developer or Blizzard Entertainment.
