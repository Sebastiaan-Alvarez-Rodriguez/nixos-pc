# nixos-pc
NixOS config for a desktop pc (amd gpu)

## Flakes

### Installation

Clone this repo, get in the project root, and execute:
```bash
sudo nixos-rebuild switch --flake .#
```

## Regular NixOS
When not dealing with flakes, we have only 3 config files:
 - `/etc/nixos/configuration.nix` (global definitions)
 - `~/.config/nixpkgs/home.nix` (local definitions)

### Installation
Get the `configuration.nix` of any host in the repo's [`/hosts/`](/hosts/) repository on your device in `/etc/nixos`, then type:
```bash
sudo nixos-rebuild switch
```

Then get the `home.nix` from any user in the repo's [`/users/`](/users/) repository on your device in `~/.config/nixpkgs/home.nix`, then type:
```bash
home-manager switch
```

# General Advice
## Development
When developing, the most important is knowing your way back in case of a screw-up.
NixOS has us covered:
```bash
sudo nixos-rebuild switch --rollback
sudo nixos-rebuild boot --rollback
...
```

The rollback commands can be repeatedly executed to keep rolling back to previous versions of your OS installation.
This does not change `/etc/nixos/configuration.nix`, however.

## Cheatsheet

```bash
nix-channel --update         # Update installed packages (requires rebuild switch for changes to take effect)
nix-collect-garbage -d       # removes previous build leftovers
nix search <package name>    # search for a nix package
man configuration.nix        # docs for /etc/nixos/configuration.nix. Note: the paths below each option are the same in the nixpkgs repo.
man home-configuration.nix   # docs for home-manager, in ~/.config/nixpkgs/home.nix
```
