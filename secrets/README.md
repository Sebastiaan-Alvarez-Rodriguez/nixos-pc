# Using secrets
Agenix provides age encryption in nixos.
It uses `sshd` to find private keys (named identities in age), and decrypts `.age` files on demand without leaking them plaintext in the nix-store.
Users can specify pairs of secrets and their belonging identities in a special file named `secrets.nix`.
A nice tutorial can be found [here](https://github.com/ryantm/agenix#tutorial).

Agenix-rekey improves upon this concept by removing the need of a `secrets.nix` file.
Instead, each host declares their belonging identities and the storage location of `.age` files for the host.
E.g. using:
```nix
age.rekey = {
  hostPubkey = "ssh-ed25519 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA+AAAAAAA";
  masterIdentities = [ "~/.ssh/deploy/identity.ed25519" "~/.ssh/deploy/backup/backup.rsa" ];
  storageMode = "local";
  localStorageDir = ../../../secrets/age/${config.my.hardware.networking.hostname};
};
```


## Creating a password/key
1. generate the key:
```bash
nix-shell -p age
echo "my secret password" | age -e -i ~/.ssh/identity.ed25519 -i ~/.ssh/deploy/another.ed25519 > encrypted.age
```
> Note: **Make sure** that you provide all the identities for all the hosts that should read this key.
> i.e. if a host 'h' has 3 master identities set, pass all 3 keys as `-i` arguments.
2. specify the secret in `/secrets/default.nix`:
```nix
secrets = {
  "path/to/file (calculated from /secrets/age/)/secret.age" = {};
};
```

## Decrypting a password/key
The easiest way:
```bash
  nix run github:oddlama/agenix-rekey -- edit
```
Then select the key to decrypt. You can also change it here.
> Note: this only works if the secret to decrypt has been specified in `/secrets/default.nix`


### Decrypting without configurations
Otherwise, use:
```bash
nix-shell -p age
age -d -i ~/.ssh/agenix hosts/helium/services/rustdesk/private-key.age
```

## Changing identity for many configurations at once
Use `/secrets/swapkey/main.py` to change identities for many secrets in one go.
