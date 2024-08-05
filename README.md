# Nix-config
Personal core declarative system and user configuration.


## Installation
The easiest way:
1. Install regular NixOS image using an USB drive.
2. Clone this repo
3. Copy the IDs of `/etc/nixos/hardware-configuration` into the `hosts/nixos/<system-name>/hardware.nix`.

Secondly, take care of a few manual steps:

* Configure Gitea and Drone
* Configure Lohr webhook and SSH key
* Configure Jellyfin
* Configure Prowlarr,Jackett and NZBHydra2
* Configure Sonarr, Radarr, Bazarr
* Configure Transmission's webui port
* Configure Quassel user
* Configure Flood account


## Updating
```bash
sudo nixos-rebuild boot --flake .#<system-name>
```
After a reboot, the changes are propagated.
To go back, just select the second-highest generation.


## Cleaning
This removes packages without pointers to them:
```bash
nix-collect-garbage -d
sudo nix-collect-garbage -d
```
The first command removes obsoleted user packages (i.e. home-manager provided ones).
The second command removes obsoleted system packages, but not user packages.

> **Note**: previous generations still point to their packages. This ensures you can go back to previous generations.


## Removing old generations
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
2. Pick a backup to restore.
3. Get the backup to a local directory using:
  ```bash
  sudo restic-<name-in-nixos> restore <SNAPSHOT> --target <path/to/local/dir/>
  ```
3. Place the backup data back where it belongs. Don't forget to re-apply `chmod` and `chown` as needed.


## TODOs
0. get rid of 'flake-parts' if possible.
1. backup postgres database.
2. Improve style: https://www.youtube.com/watch?v=ptmiPG_V4u8

## Resources
1. Install flake using script: https://dzone.com/articles/nixos-native-flake-deployment-with-luks-and-lvm
2. Overrides in multiple ways: https://bobvanderlinden.me/customizing-packages-in-nix/
