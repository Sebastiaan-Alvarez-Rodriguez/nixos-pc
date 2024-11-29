# Using secrets
Agenix provides age encryption in nixos.
It uses `sshd` to find private keys, and decrypts `.age` files on demand without leaking them plaintext in the nix-store.

A nice tutorial can be found [here](https://github.com/ryantm/agenix#tutorial).

## Decrypting a password/key
Requires you to define secret files in your configurations like this:
```nix
  age.secrets.secret1.file = path/to/file.age;
```

Using nixOS, In your config:
```nix
{
  users.users.example-user= {
    isNormalUser = true;
    passwordFile = config.age.secrets.secret1.path;
  };
}
```

### Decrypting without configurations
Explicitly using commandline:
```bash
nix run github:ryantm/agenix -- -d path/to/file.age --identity path/to/private/key
```


## Encrypting a password/key
First ensure a file named `secrets.nix` exists in your current directory, containing:
```nix
let
  key = "ssh-rsa ........"; # the public key to encrypt with. Note: NixOS provides builtins.readFile as well.
in {
  "path/to/newfile.age".publicKeys = [ key ];
}
```
Using commandline (ensure `newfile.age` does not exist yet):
```bash
nix run github:ryantm/agenix -- -e path/to/newfile.age --identity path/to/private/key
```


## Future work
- Use agenix without managing a secrets.nix using [agenix-rekey](https://github.com/oddlama/agenix-rekey).
