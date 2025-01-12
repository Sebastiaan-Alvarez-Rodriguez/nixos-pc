# defaults file - imported by flake, to build age config (pointing names to encrypted age files).
{ config, inputs, lib, ... }: let
  cfg = config.my.services.secrets;
in {
  imports = [ inputs.agenix.nixosModules.age ];

  options.my.services.secrets = with lib; {
    hosts = mkOption {
      type = with types; listOf (str);
      description = "List of hostnames to load keys for in this build";
      example = [ "host1" "host2" ];
      default = [ config.my.hardware.networking.hostname ];
    };
  };
  config.age = {
    identityPaths = let
      normalUsers = builtins.attrNames (lib.filterAttrs (n: v: v.isNormalUser) config.users.users); # NOTE: all normal i.e. user-defined users.
    in builtins.map (user: "/home/${user}/.ssh/agenix") normalUsers;
    secrets = let
      toName = lib.removeSuffix ".age";
      userExists = u: builtins.hasAttr u config.users.users; # Only set the user if it exists, to avoid warnings
      userIfExists = u: if userExists u then u else "root";
      toSecret = name: { owner ? "root", ... }: {
        # This function passes an optional 'owner = "<name>"' to agenix (which will set the decrypted secrets as readable to this user).
        # It can be set in the secrets.nix file in the key definitions.
        file = ./. + "/${name}";
        owner = lib.mkDefault (userIfExists owner);
      };
      convertSecrets = n: v: lib.nameValuePair (toName n) (toSecret n v);
      filterpred =  hostnames: name: lib.my.hasprefix-any (lib.map (e: "hosts/${e}/") hostnames) name;
      filterSecretsForHosts = hostnames: attrs: lib.filterAttrs (n: v: (filterpred hostnames n)) attrs;
      secrets = import ./secrets.nix;
    in
      lib.mapAttrs' convertSecrets (filterSecretsForHosts cfg.hosts secrets);
  };
}
