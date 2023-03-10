# Blackberry
A flake for a raspberry pi 3b+ model.

## Building Image
A raspberry Pi needs an image on an SD card to start.
To build the image, use:
```bash
nix build ".#images.blackberry"
```

To write the image on an SD card, use:
```bash
lsblk #find the SD card
sudo gdisk # remove old partitions using gdisk UI
sudo dd if=result/sd-image/nixos-sd-image-22.11.20221215.0152de2-aarch64-linux.img of=/dev/sdX bs=1024k status=progress
```

## Troubleshooting

### ell-0.53
Full Error:
```
warning: Git tree '/home/rdn/projects/nixos-pc' is dirty
error: builder for '/nix/store/9gc4if10rcp1vnfd019yjsp262xggdpn-ell-0.53.drv' failed with exit code 2;
       last 10 log lines:
       > # FAIL:  1
       > # XPASS: 0
       > # ERROR: 0
       > ============================================================================
       > See ./test-suite.log
       > ============================================================================
       > make[3]: *** [Makefile:2130: test-suite.log] Error 1
       > make[2]: *** [Makefile:2238: check-TESTS] Error 2
       > make[1]: *** [Makefile:2743: check-am] Error 2
       > make: *** [Makefile:2745: check] Error 2
       For full logs, run 'nix log /nix/store/9gc4if10rcp1vnfd019yjsp262xggdpn-ell-0.53.drv'.
error: 1 dependencies of derivation '/nix/store/lnbmgsp7gysma2j2ghq4d73k6lyp35g6-bluez-5.65.drv' failed to build
error: 1 dependencies of derivation '/nix/store/g6axsa3ldkpgczzg79i4wwpj0hgi0b16-networkmanager-1.40.2.drv' failed to build
error (ignored): error: cannot unlink '/tmp/nix-build-openvpn-2.5.8.drv-2/openvpn-2.5.8': Directory not empty
error: 1 dependencies of derivation '/nix/store/8ks142c1w6451r6f06v5kxf39zvhl8sq-NetworkManager-fortisslvpn-1.4.0.drv' failed to build
error: 1 dependencies of derivation '/nix/store/
```

Solution: Do not set `networking.networkManager.enable=true`.

## Intel
 - Minimal example: https://github.com/jhillyerd/nixos-minimal-raspberrypi3-flake
 - Another example: https://github.com/MatthewCroughan/raspberrypi-nixos-example
 - Tutorial: https://myme.no/posts/2022-12-01-nixos-on-raspberrypi.html