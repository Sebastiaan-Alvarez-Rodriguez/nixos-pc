# Working with custom keyboards
There are many Custom keyboards out there. I recently got a `josefadamcik/sofle v2` split keyboard, and better write down what I did for future reference.

## setup
1. install `qmk` (a commandline utility)
2. run `qmk setup` (answer `Y` when asked to clone some git repo)

## flash config
I used [qmk configurator](https://config.qmk.fm/#/sofle/rev1/LAYOUT) to create a keymap.
Make sure to select the `sofle/rev1` keyboard here in the `KEYBOARD` field. Do **not** use `splitkb/aurora/sofle_v2/rev1`, because that's another board.

1. When the config is ready, download the `keymap.json` to this directory (<project root>/keyboard/keymap.json).
2. execute command (command compiles json, adds `custom.c` code and then waits for kb):
```bash
./compile.sh
```
2. ensure the keyboard is normally attached (usb-c in left-part, connected to right part using TRRS cable)
3. make kb available for flashing by putting it in 'reset' or 'bootloader' mode:
  - option 1: press the little flash button just below the controller
  - option 2: quickly tap to connect the RST and GND pin twice within a second. This is the 'hardware' variant of putting it in bootloader mode.
4. wait until flashed

Then the left part works. For the right part:
1. unplug usb-c from left part
2. remove the TRRS cable between keyboard parts
3. plug usb-c to right part
4. repeat steps 2-4 above for the right part


## Intel
- Translate keymap json to c: `json2c json2c keymap.json -o keymap.c`
- Inside the `.c` file, we can add extra stuff, like changing what rotary encoders do.
- to use the keymap.c, we need to copy it over to `~/qmk_firmware/keyboards/sofle/keymaps/<layout-name>`. We can then flash it using `qmk flash -kb "$KEYBOARD" -km "<layout-name>" -bl avrdude`
