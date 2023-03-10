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

```

## Current error
Occurs with build command.
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
error: 1 dependencies of derivation '/nix/store/8sc9sx36y7lmzmvw11wmgr3lbl4wirbj-NetworkManager-iodine-unstable-2019-11-05.drv' failed to build
error: 1 dependencies of derivation '/nix/store/bpplxabvmaxdbcw1lhs3i9lnd1x97pyh-NetworkManager-l2tp-1.20.4.drv' failed to build
error: 1 dependencies of derivation '/nix/store/avla2d1pqviway0n8zk2mb5wb4blh4wi-NetworkManager-openconnect-1.2.8.drv' failed to build
error: 1 dependencies of derivation '/nix/store/as78l2vg1qcb7hjdrdywq20arsqxgy5k-NetworkManager-openvpn-1.10.0.drv' failed to build
error: 1 dependencies of derivation '/nix/store/6dymh90a4d7axn99n61gh1n44g7gfpyr-NetworkManager-vpnc-1.2.8.drv' failed to build
error: 1 dependencies of derivation '/nix/store/pr43krp44kc4ljamglnpcskj6cg55k3y-dbus-1.drv' failed to build
error: 1 dependencies of derivation '/nix/store/phm9y81awwxrfdy326m0mchbrxcvym4m-system-path.drv' failed to build
error: 1 dependencies of derivation '/nix/store/pbw4nr774vr7v9kkmcm28cg1qpclhllh-nixos-system-blackberry-22.11.20221215.0152de2.drv' failed to build
error: 1 dependencies of derivation '/nix/store/92929xsrh98xqrf842k86j4vcm1525xd-ext4-fs.img.drv' failed to build
error: 1 dependencies of derivation '/nix/store/9azph5rmsgazqridr71daps9nh98fw1j-nixos-sd-image-22.11.20221215.0152de2-aarch64-linux.img.drv' failed to build
```

## Intel
 - Minimal example: https://github.com/jhillyerd/nixos-minimal-raspberrypi3-flake
 - Tutorial: https://myme.no/posts/2022-12-01-nixos-on-raspberrypi.html