# Nix-config
Personal core declarative system and user configuration.

## TODOs

1. get rid of `ambroisie` in `pkgs.ambroisie.<pkg-name>` (probably alias somewhere?).
2. get rid of `ambroisie` in the entire project.

## Steps

First build using flakes:

```sh
sudo nixos-rebuild switch --flake .
```

Secondly, take care of a few manual steps:

* Configure Gitea and Drone
* Configure Lohr webhook and SSH key
* Configure Jellyfin
* Configure Prowlarr,Jackett and NZBHydra2
* Configure Sonarr, Radarr, Bazarr
* Configure Transmission's webui port
* Configure Quassel user
* Configure Flood account
