# secrets file - points encrypted age files to the public keys they where encrypted with (needed to decrypt).
let
  inherit (builtins) readFile stringLength substring;
  removeSuffix = suffix: str: let
    sufLen = stringLength suffix;
    sLen = stringLength str;
  in
    if sufLen <= sLen && suffix == substring (sLen - sufLen) sufLen str then substring 0 (sLen - sufLen) str else str;
  addContextFrom = src: target: substring 0 0 src + target;
  splitString = sep: s: let
    splits = builtins.filter builtins.isString ( builtins.split (builtins.toString sep) (toString s) );
  in map (addContextFrom s) splits;

  read-key = f: removeSuffix "\n" (readFile f);
  common-keys = builtins.map read-key [ users/rdn/deploy/common-deploy.ed25519.pub users/rdn/deploy/agenix.pub ]; 
  host-specific-keys = {
    blackberry = [ users/rdn/deploy/blackberry-deploy.ed25519.pub users/rdn/deploy/agenix.pub ];
    helium = [ users/rdn/deploy/helium-deploy.ed25519.pub users/rdn/deploy/agenix.pub ];
    xenon = [ users/rdn/deploy/xenon-deploy.ed25519.pub users/rdn/deploy/agenix.pub ];
  };

  get-hostname = k: (builtins.elemAt (splitString "/" k) 1);
  select-keys = k: if (builtins.substring 0 6 k) == "common" then common-keys else (host-specific-keys."${(get-hostname k)}"); 
  process = dict: builtins.mapAttrs (k: v: v // {publicKeys = (if (builtins.hasAttr "publicKeys" v) then v.publicKeys else []) ++ (select-keys k);}) dict;
  # Seb TODO: change base to have multiple keys.
  # Think of:
  # 1. MRS also must be able to use. (just pass multiple pub keys) (see: https://github.com/ryantm/agenix)
  # 2. Does 1 mean that the user must have both keys? Or just one?
  # 3. And can a user do a -rekey- or -encrypt- while having only 1 of multiple private keys?
  # 4. Do we want separate keys from ssh access keys?
  # 5. Do we want different keys between users? (probably yes?)
in process {
  "common/ddns/api-key.age" = { owner = "ddclient"; };
  "common/ddns/secret-api-key.age" = { owner = "ddclient"; };

  # note: by default, only keys starting with "hosts/<hostname>/..." are loaded for host named "hostname" (as provided in config.my.hardware.networking.hostname)
  "hosts/blackberry/services/backup-server/blackberry.age" = { owner = "restic"; };
  # "hosts/helium/services/backup-client/blackberry-client-helium.age".publicKeys = [ base ];
  "hosts/helium/services/backup-client/xenon-client-helium.age" = {};
  "hosts/helium/services/backup-client/repo-helium.age" = {};
  "hosts/helium/services/backup-server/helium.age" = { owner = "restic"; };
  "hosts/helium/services/monitoring/password.age" = { owner = "grafana"; };
  "hosts/helium/services/monitoring/secret-key.age" = { owner = "grafana"; };
  "hosts/helium/services/nginx/auth-key.age" = {};
  "hosts/helium/services/nginx/rdn-totp.age" = {};
  "hosts/helium/services/nginx/rdn-pass.age" = {};
  "hosts/helium/services/rustdesk/private-key.age" = { owner = "rustdesk"; };
  "hosts/helium/services/rustdesk/public-key.age" = { owner = "rustdesk"; };
  "hosts/helium/services/syncthing/cert.age" = { owner = "restic"; };
  "hosts/helium/services/syncthing/key.age" = { owner = "restic"; };
  "hosts/helium/services/transmission/secret.age" = {};
  "hosts/helium/services/tandoor-recipes/secret.age" = {};
  "hosts/helium/services/vikunja/mail.age" = {};

  "hosts/xenon/services/backup-client/helium-client-xenon.age" = {};
  "hosts/xenon/services/backup-client/repo-xenon.age" = {};
  "hosts/xenon/services/mail/vikunja.age" = {};
  "hosts/xenon/services/backup-server/xenon.age" = { owner = "restic"; };
}
