#!/bin/sh
set -eu

KEYBOARD="sofle"
LAYOUT="mylayout"

QMK_DIR="$HOME/qmk_firmware"
DEST="$QMK_DIR/keyboards/$KEYBOARD/keymaps/$LAYOUT"

mkdir -p "$DEST"

qmk json2c keymap.json > keymap.c

tmp=$(mktemp)

{
  echo '#define OTHER_KEYMAP_C "custom.c"'
  cat keymap.c
} > "$tmp"

mv "$tmp" keymap.c

cp keymap.c "$DEST/"
cp custom.c "$DEST/"

[ -f rules.mk ] && cp rules.mk "$DEST/"
[ -f config.h ] && cp config.h "$DEST/"

echo "Copied files to:"
echo "  $DEST"

qmk flash -kb "$KEYBOARD" -km "$LAYOUT" -bl avrdude
