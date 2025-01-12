# secrets file - points encrypted age files to the public keys they where encrypted with (needed to decrypt).
let
  inherit (builtins) readFile stringLength substring;
  removeSuffix = suffix: str: let
    sufLen = stringLength suffix;
    sLen = stringLength str;
  in
    if sufLen <= sLen && suffix == substring (sLen - sufLen) sufLen str then substring 0 (sLen - sufLen) str else str;

  readKey = f: removeSuffix "\n" (readFile f);
  base = readKey keys/users/rdn.rsa.pub; 
in {
  # note: by default, only keys starting with "hosts/<hostname>/..." are loaded for host named "hostname" (as provided in config.my.hardware.networking.hostname)
  "hosts/helium/services/backup-server/xenon-client-helium.age".publicKeys = [ base ];
  "hosts/helium/services/backup-server/repo-helium.age".publicKeys = [ base ];
  "hosts/helium/services/transmission/secret.age".publicKeys = [ base ];
  # "hosts/helium/services/pyload/secret.age".publicKeys = [ base ];
  # "hosts/helium/services/tandoor-recipes/secret.age".publicKeys = [ base ];

  "hosts/xenon/services/backup-server/xenon.age" = {
    publicKeys = [ base ];
    owner = "restic";
  };
}
