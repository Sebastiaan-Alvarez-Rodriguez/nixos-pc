# secrets file - points encrypted age files to the public keys they where encrypted with (needed to decrypt).
let
  inherit (builtins) readFile stringLength substring;
  removeSuffix = suffix: str: let
    sufLen = stringLength suffix;
    sLen = stringLength str;
  in
    if sufLen <= sLen && suffix == substring (sLen - sufLen) sufLen str then substring 0 (sLen - sufLen) str else str;

  readKey = f: removeSuffix "\n" (readFile f);
  k = readKey keys/users/rdn.rsa.pub;
in {
  "users/rdn/host-password.age".publicKeys = [ k ];
}
