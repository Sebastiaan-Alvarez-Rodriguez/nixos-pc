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
