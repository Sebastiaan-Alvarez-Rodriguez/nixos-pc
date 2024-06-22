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
1. get rid of `ambroisie` in the entire project.
2. get rid of `belanyi.fr` in the entire project.
