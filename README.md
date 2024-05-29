# nixos-pc
NixOS configs for:

 - [`blackberry`](hosts/blackberry): Raspberry pi 3b+ (with custom installation instructions) running a local backup service.
 - `neon`: mini home server.
 - `polonium`: Laptop host (nvidia gpu).
 - `radon`: Main host (amd gpu)
 - `xenon`: Server containing mail, password service, and backups of local devices.

## Flakes
### Installation

Clone this repo, get in the project root, and execute:
```bash
sudo nixos-rebuild switch --flake .#<HOST>
home-manager switch --flake .#<USER>
```

 > For available `HOSTs`, check the [`/hosts/`](/hosts/) directory.

 > For available `USERs`, check the [`/users/`](/users/) directory.

#### Installing from nixos live usb

Clone this repo, get in the project root, and execute:
```bash
sudo mount /dev/<ROOT_PARTITION> /mnt
sudo mount /dev/<bOOT_PARTITION> /mnt/boot
```

Next, display the hardware configuration from:
```bash
sudo generate-nixos-conf --show-hardware-conf
```
Check for the UUID's of the `/mnt` and `/mnt/boot` filesystems.
Place those UUID's inside the `hardware-configuration.nix` from this repo.

From the root of this project:
```bash
sudo nixos-install --flake .#<HOST>
```

After installation, do not forget to clone this repo in the installed NixOS and execute:
```bash
home-manager switch --flake .#<USER>
```

## General info
### Installing NixOS on a running instance
I have never seen a VPS provider which provides NixOS images out of the box.
You can pay to provide your own image.
Alternatively, a much better option is to use [`nixos-infect`](https://github.com/elitak/nixos-infect).


### Upgrading NixOS
NixOS brings new releases on the 5'th and 11'th month of each year.
To upgrade, we must change the nixos channel.
1. Check your current nixos channel with:
```bash
sudo nix-channel --list | grep nixos
```
2. Change using:
```bash
sudo nix-channel --add https://channels.nixos.org/[SOME-NAME-HERE] nixos
```
Common names follow format `nixos-[VERSION]`.
3. Then, upgrade using:
```bash
sudo nixos-rebuild switch --upgrade # regular NixOS
sudo nixos-rebuild switch --flake .#[FLAKE] --upgrade # flakes
```


### Regular NixOS
When not dealing with flakes, we have only 3 config files:
 - `/etc/nixos/configuration.nix` (global definitions)
 - `~/.config/nixpkgs/home.nix` (local definitions)

#### Installation
Get the `configuration.nix` of any host in the repo's [`/hosts/`](/hosts/) repository on your device in `/etc/nixos`, then type:
```bash
sudo nixos-rebuild switch
```

Then get the `home.nix` from any user in the repo's [`/users/`](/users/) repository on your device in `~/.config/nixpkgs/home.nix`, then type:
```bash
home-manager switch
```

## Cheatsheet
```bash
nix-channel --update         # Update installed packages (requires rebuild switch for changes to take effect)
nix-collect-garbage -d       # removes previous build leftovers
nix search <package name>    # search for a nix package
man configuration.nix        # docs for /etc/nixos/configuration.nix. Note: the paths below each option are the same in the nixpkgs repo.
man home-configuration.nix   # docs for home-manager, in ~/.config/nixpkgs/home.nix
```

## Recover
When developing, the most important is knowing your way back in case of a screw-up.
NixOS has us covered:
```bash
sudo nixos-rebuild switch --rollback
sudo nixos-rebuild boot --rollback
...
```

The rollback commands can be repeatedly executed to keep rolling back to previous versions of your OS installation.
This does not change `/etc/nixos/configuration.nix`, however.


## Errors

### DBI connect
When running some command (e.g. `git`):
```bash
$ git
DBI connect('dbname=/nix/var/nix/profiles/per-user/root/channels/nixos/programs.sqlite','',...) failed: unable to open database file at /run/current-system/sw/bin/command-not-found line 13.
cannot open database '/nix/var/nix/profiles/per-user/root/channels/nixos/programs.sqlite' at /run/current-system/sw/bin/command-not-found line 13.
```

Fix:
This happens when the `root` user is missing the nixos channel. You can fix this by adding a channel and naming it nixos:
```bash
sudo nix-channel --add https://nixos.org/channels/nixos-VERSION nixos
sudo nix-channel --update nixos
```

## Resources

 - NixOS development (direnv): https://xeiaso.net/blog/how-i-start-nix-2020-03-08
 - Specific versions (direnv): https://discourse.nixos.org/t/specifying-package-version-in-shell-nix%2F8513
