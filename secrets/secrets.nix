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
  "services/tandoor-recipes/secret.age".publicKeys = [ base ];
  "services/pyload/secret.age".publicKeys = [ base ];
  "services/backup-server/xenon-client-helium.age".publicKeys = [ base ];
  "services/backup-server/xenon-repo-helium.age".publicKeys = [ base ];
  "services/backup-server/xenon.age" = {
    publicKeys = [ base ];
    owner = "restic";
  };
}
