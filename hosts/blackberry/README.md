# Blackberry
A flake for a raspberry pi 3b+ model.

## Building Image
A raspberry Pi needs an image on an SD card to start.

### `aarch64` compilation
Assuming you have a `x64_86` machine from where you build, you need to either:
 - cross-compile
 - enable emulator on your build host.

This flake is built with this last option in mind.
Simply add the following to the `configuration.nix` for your host:
```nix
# Emulate for aarch64-linux builds
boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
```

Then rebuild (`sudo nixos-rebuild switch...`) your host.

### Building
To build the image, use:
```bash
nix build ".#images.blackberry"
```

### Deployment
#### Initial
To write the image on an SD card, use:
```bash
lsblk #find the SD card
sudo --preserve-env gparted # remove old partitions using gdisk UI
sudo dd if=result/sd-image/nixos-sd-image-VERSION.DATE.HASH-aarch64-linux.img of=/dev/sdX bs=1024k status=progress
```

Insert the SD in the raspberry Pi.
It will automatically boot once powered.

#### Afterwards
Once NixOS is running, you can build and deploy on the raspberry itself.
However, it is slow to do this.
You can also remote-build and deploy to the raspberry.
This means: Build on a beefy machine, deploy to a weak machine (in this case a raspberry).

On the build host, ensure you have:
```nix
boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
```
Also ensure you have an entry in your `~/.ssh/config` for the raspberry with passwordless authentication.

Then, use:
```bash
NIX_SSHOPTS="-t" nixos-rebuild switch --flake .#blackberry --target-host blackberry-local --use-remote-sudo
```
> **Note**: You sometimes have to fill in the sudo password for the raspberry.

> **Note**: If the process seems to do nothing for a bit (e.g. 20 seconds), just hit enter. Probably it asked for remote sudo password again, but the line got overridden in terminal or something.

> **Note**: It might be possible to remove the need for filling the sudo password of the raspberry, if you setup passwordless authentication for `root` as well, and use `sudo` on the build-and-deploy command.

### Connecting
Once booted, a basic SSH connection will be open, for user `rdn` and password `changeme`.
To find the ip-address of the raspberry, either:

 - Have your router tell you what devices are connected. It is the one called `Blackberry`.
 - Use `nmap 192.168.178.0/24 -sn` to get a fast list of IPs to try. Remove `-sn` to allow port scanning (takes longer, you might want to remove the /24 & set an IP address to check).
 - Connect a screen and keyboard to the Raspberry Pi, login locally, and type `ifconfig` or `ip r`

### Runtime Configuration

> **Hey you**, change your password right after your first SSH connection.

Execute the following commands to follow the nixos channel for a given version:
```bash
sudo nix-channel --add https://nixos.org/channels/nixos-VERSION nixos
sudo nix-channel --update nixos
```

Use `scp`/`rsync` to copy this repo over to the Raspberry Pi.
Then execute (on the Raspberry Pi):
```bash
nix-shell -p git home-manager

home-manager switch --flake .#rdn-blackberry-min
```

This will install the `rdn-blackberry-min` profile.


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
