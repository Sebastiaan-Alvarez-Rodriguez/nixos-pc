# Working with custom keyboards
There are many Custom keyboards out there. I recently got a `josefadamcik/sofle v2` split keyboard, and better write down what I did for future reference.

## setup
1. install `qmk` (a commandline utility)
2. run `qmk setup` (answer `Y` when asked to clone some git repo)

## create keymap
I used [qmk configurator](https://config.qmk.fm/#/sofle/rev1/LAYOUT) to create a keymap.
Make sure to select the `sofle/rev1` keyboard here in the `KEYBOARD` field. Do **not** use `splitkb/aurora/sofle_v2/rev1`, because that's another board.

When the config is ready, download the `keymap.json`.

## flash config
I assume you have the left part of the split keyboard attached to usb-c.

For the left part:
1. execute command (command compiles stuff and then waits for kb):
```bash
qmk flash -kb sofle path/to/layout.json -bl avrdude
```
2. make kb available for flashing by putting it in 'reset' or 'bootloader' mode:
  - option 1: use the RESET keybind. Needs you to have this bind and remember it.
  - option 2: quickly tap to connect the RST and GND pin twice within a second. This is the 'hardware' variant of putting it in bootloader mode.
3. wait until flashed

Then the left part works. For the right part:
1. unplug usb-c from left part
2. remove the TRRS cable between keyboard parts
3. plug usb-c to right part
4. repeat the steps for the right part
