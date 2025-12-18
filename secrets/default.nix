# defaults file - imported by flake, to build age config (pointing names to encrypted age files).
{ config, inputs, lib, ... }: let
  cfg = config.my.services.secrets;
in {
  imports = [ inputs.agenix.nixosModules.age ];

  options.my.services.secrets = with lib; {
    prefixes = mkOption {
      type = with types; listOf (str);
      description = "List of filepath prefixes to load keys for in this build";
      example = [ "host1" "host2" ];
      default = [ ]; # always includes hosts/<hostname>
    };
  };
  config = {
    age.secrets = let
      toName = lib.removeSuffix ".age";
      userExists = u: builtins.hasAttr u config.users.users; # Only set the user if it exists, to avoid warnings
      userIfExists = u: if userExists u then u else "root";
      toSecret = name: { owner ? "root", ... }: {
        # This function passes an optional 'owner = "<name>"' to agenix (which will set the decrypted secrets as readable to this user).
        # It can be set in the secrets.nix file in the key definitions.
        rekeyFile = ./age + "/${name}";
        owner = lib.mkDefault (userIfExists owner);
      };
      process = n: v: lib.nameValuePair (toName n) (toSecret n v);
      secrets = {
        "common/ddns/api-key.age" = { owner = "ddclient"; };
        "common/ddns/secret-api-key.age" = { owner = "ddclient"; };

        # note: by default, only keys starting with "hosts/<hostname>/..." are loaded for host named "hostname" (as provided in config.my.hardware.networking.hostname)
        "blackberry/backup-server/blackberry.age" = { owner = "restic"; };
        # "helium/backup-client/blackberry-client-helium.age".publicKeys = [ base ];
        "helium/backup-client/xenon-client-helium.age" = {};
        "helium/backup-client/repo-helium.age" = {};
        "helium/backup-server/helium.age" = { owner = "restic"; };
        "helium/monitoring/password.age" = { owner = "grafana"; };
        "helium/monitoring/secret-key.age" = { owner = "grafana"; };
        "helium/nginx/auth-key.age" = {};
        "helium/nginx/rdn-totp.age" = {};
        "helium/nginx/rdn-pass.age" = {};
        "helium/rustdesk/private-key.age" = { owner = "rustdesk"; };
        "helium/rustdesk/public-key.age" = { owner = "rustdesk"; };
        "helium/syncthing/cert.age" = { owner = "restic"; };
        "helium/syncthing/key.age" = { owner = "restic"; };
        "helium/transmission/secret.age" = {};
        "helium/tandoor-recipes/secret.age" = {};
        "helium/vikunja/mail.age" = {};

        "xenon/backup-client/helium-client-xenon.age" = {};
        "xenon/backup-client/repo-xenon.age" = {};
        "xenon/mail/mail.age" = {};
        "xenon/mail/mariska.age" = {};
        "xenon/mail/noreply.age" = {};
        "xenon/mail/sebastiaan.age" = {};
        "xenon/mail/vikunja.age" = {};
        "xenon/backup-server/xenon.age" = { owner = "restic"; };
      };
    in 
      lib.mapAttrs' process secrets;
  };
}
