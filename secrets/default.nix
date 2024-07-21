# defaults file - imported by flake, to build age config (pointing names to encrypted age files).
{ config, inputs, lib, ... }: {
  imports = [ inputs.agenix.nixosModules.age ];

  config.age = {
    identityPaths = let
      normalUsers = builtins.attrNames (lib.filterAttrs (n: v: v.isNormalUser) config.users.users); # NOTE: all normal i.e. user-defined users.
    in builtins.map (user: "/home/${user}/.ssh/agenix") normalUsers;
    secrets = let
      toName = lib.removeSuffix ".age";
      userExists = u: builtins.hasAttr u config.users.users;
      # Only set the user if it exists, to avoid warnings
      userIfExists = u: if userExists u then u else "root";
      toSecret = name: { owner ? "root", ... }: {
        file = ./. + "/${name}";
        owner = lib.mkDefault (userIfExists owner);
      };
      convertSecrets = n: v: lib.nameValuePair (toName n) (toSecret n v);
      secrets = import ./secrets.nix;
    in
      lib.mapAttrs' convertSecrets secrets;
      # secrets = {"path/bla/secret.age": [ "ssh-rsa ...." ]; }
      # nameValuePair "some" 6 => { name = "some"; value = 6; }
      # will be like:
      # { "path/bla/secret": { file: ./.path/bla/secret.age; owner = "root";}}
  };
}
