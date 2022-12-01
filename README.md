# nixos-pc
NixOS config for a desktop pc (amd gpu)

## Installation
Get this repository on your device in `/etc/nixos`, then type:
```bash
sudo nixos-rebuild switch
```


## Development
When developing, the most important is knowing your way back in case of a screw-up.
NixOS has us covered:
```bash
sudo nixos-rebuild switch --rollback
sudo nixos-rebuild boot --rollback
...
```

The rollback commands can be repeatedly executed to keep rolling back to previous versions.
This does not change your `configuration.nix`, however.

### Cheatsheet

```bash
nix-channel --update         # Update installed packages (requires rebuild switch for changes to take effect)
nix-collect-garbage -d       # removes previous build leftovers
nix search <package name>    # search for a nix package
man configuration.nix        # docs for /etc/nixos/configuration.nix. Note: the paths below each option are the same in the nixpkgs repo.
man home-configuration.nix   # docs for home-manager, in ~/.config/nixpkgs/home.nix
```
