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
sudo nix-collect-garbage -d
```
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


## TODOs
0. get rid of 'flake-parts' if possible.
1. create custom postgresql service with datadir on LVM array (https://search.nixos.org/options?channel=24.05&show=services.postgresql.dataDir&from=0&size=50&sort=relevance&type=packages&query=services.postgresql)


## Resources
1. Install flake using script: https://dzone.com/articles/nixos-native-flake-deployment-with-luks-and-lvm
2. Overrides in multiple ways: https://bobvanderlinden.me/customizing-packages-in-nix/
