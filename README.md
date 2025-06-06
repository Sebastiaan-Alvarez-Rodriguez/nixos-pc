# Nix-config
Personal core declarative system and user configuration.
Inspired from [this config](https://github.com/ambroisie/nix-config/tree/main).




## Installation
### Installing NixOS on a VPS instance
To install NixOS on a VPS: [`nixos-infect`](https://github.com/elitak/nixos-infect).

### Installing NixOS directly on medium
#### SD card
To build the image, add the following configuration in [flake/nixos.nix](/flake/nixos.nix) (for a nixos configuration called `<NAME>``):
```nix
flake.images = {
  <NAME> = flake.nixosConfigurations.<NAME>.config.system.build.sdImage;
};
```
Of course, ensure you have defined `flake.nixosConfigurations.<NAME>`.

Then:
```bash
nix build ".#images.<NAME>"
```



## Updating
```bash
nix flake update
sudo nixos-rebuild boot --flake .#<system-name>
```
After a reboot, the changes are propagated.
To go back, just select the second-highest generation.

### Major version upgrading
NixOS brings new releases on the 5'th and 11'th month of each year. To upgrade, change the nixos channel in `flake.nix`.



## deployment
### regular update
```bash
sudo nixos-rebuild switch --flake .#<system-name>
```
> **NOTE**: some services only change after a reboot. It is better for your systems to just use `nixos-rebuild boot` instead of `switch`.

### SD card
To write and sd-card image on an SD card (see [Installation](#Installation)), use:
```bash
lsblk #find the SD card
sudo --preserve-env gparted # remove old partitions using gdisk UI
sudo dd if=result/sd-image/nixos-sd-image-VERSION.DATE.HASH-aarch64-linux.img of=/dev/sdX bs=1024k status=progress
```

> **NOTE**: If this image is for some low-resource device, never update/upgrade your distribution, it cannot handle it. Instead, use [Remote deployment](#Remote%20deployment).

### Remote Deployment
This means: Build on a beefy machine (the build host), deploy to a weak machine (the target host).

On the build host, ensure you have either the same arch, or a different arch but with emulated system for the remote.
For example, if the build host has `x86_64` and the remote is `aarch64-linux`, then emulate `aarch64-linux` on the build host:
```nix
boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
```

Ensure you have an entry in your `~/.ssh/config` for the target with passwordless authentication.
Then, use:
```bash
NIX_SSHOPTS="-t" nixos-rebuild switch --flake .#blackberry --target-host blackberry-local --use-remote-sudo
```

> **Note**: You sometimes have to fill in the sudo password for the raspberry.

> **Note**: If the process seems to do nothing for a bit (e.g. 20 seconds), just hit enter. Probably it asked for remote sudo password again, but the line got overridden in terminal or something.

> **Note**: It might be possible to remove the need for filling the sudo password of the raspberry, if you setup passwordless authentication for `root` as well, and use `sudo` on the build-and-deploy command.



## Cleaning
This removes packages without pointers to them:
```bash
nix-collect-garbage -d
sudo nix-collect-garbage -d
```
The first command removes obsoleted user packages (i.e. home-manager provided ones).
The second command removes obsoleted system packages, but not user packages.

> **Note**: previous generations still point to their packages. This ensures you can go back to previous generations.


### Removing old generations
> **Warning**: Do this only when you are sure your current generation works as it should, after you have rebooted at least once.

List all available generations with:
```bash
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
```

Delete generations with:
```bash
sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations 1 2 3 <any other generation numbers>
```



## Applying backups
Where backups are used, the implementation is [`restic`](https://restic.readthedocs.io/en/latest/index.html).

To restore a backup after disaster:
1. List your backup snapshots:
  ```bash
  sudo restic-<name-in-nixos> snapshots
  ```
2. Pick a backup to restore by using it's hash.
3. Get the backup to a local directory using:
  ```bash
  sudo restic-<name-in-nixos> restore <SNAPSHOT-hash> --target <path/to/local/dir/>
  ```
  E.g. to take the latest snapshot (check if the latest is ok) and automatically restore it, use:
  ```bash
  sudo restic-<name-in-nixos> restore latest --target /
  ```
  > **NOTE**: Optionally, use `--include /some/path` to only include one path from the backup instead of fetching everything.
4. Restore specific dumps:
  - postgresql
  - home-assistant
  - photoprism

### Postgresql
This is needed when the original data is no longer loaded, e.g. due to a host change / storage change.
It should look like:
1. Check database names:
```bash
sudo psql -l
```
2. Stop active connections:
```bash
sudo systemctl stop vaultwarden kitchenowl-backend home-assistant
```
3. Drop databases one by one:
```bash
sudo dropdb <database-name>
```
4. Deflate backup file:
```bash
unzstd <filename>.sql.zstd
```
5. Apply backup file:
```bash
psql -X -f <path/to/filename>.sql -d postgres
```
6. Restart stopped services

7. Check if it worked:
```bash
psql -d <some-database> -c "SELECT * FROM <some-table>;"
```
Pick a database and table which should contain info, and check the results.


## Exposed data
This repo exposes **packages**, **overlays**, and **modules**.
To see what is exposed for other flakes to depend on, use:
```bash
nix flake show .
```

For the modules, you can only see 1 wrap named `nixos-pc`. To better see what modules are exposed exactly:
```bash
nix eval '.#nixosModules.nixos-pc'
nix eval '.#nixosModules.nixos-pc' | nixfmt # for pretty printing
```

## TODOs
1. Improve security: https://discourse.nixos.org/t/automatically-ban-ports-scanner-ips-on-nixos/22110
   Also - check out crowdsec.
2. Improve style: https://www.youtube.com/watch?v=ptmiPG_V4u8
3. laptop fan control: https://wiki.archlinux.org/title/Fan_speed_control

## Resources
1. Install flake using script: https://dzone.com/articles/nixos-native-flake-deployment-with-luks-and-lvm
2. Overrides in multiple ways: https://bobvanderlinden.me/customizing-packages-in-nix/




