{age-secrets}: { # the IDs are not secret at all, src: https://forum.syncthing.net/t/should-i-keep-my-node-ids-as-secret-as-possible/230
  "helium" = {
    id = "FOGGQVK-QV6ZQRK-NUAE2D3-TCO7FSH-NAUPR6P-NGZ3II6-X57XYR2-EEBTRAH";
    private-keyfile = age-secrets."helium/syncthing/key".path;
    certfile = age-secrets."helium/syncthing/cert".path;
  };
  "rdn-phone" = {
    id = "NABS66G-LYDPC6H-QWVOGEX-YGMA7NS-HTDHYNH-RYKPW67-7QVK4XY-RAP7MQM";
    autoAcceptFolders = true;
  };
  "mrs-phone" = {
    id = "XKNAT35-HIFXMY2-WARTHTQ-7VDDOYD-J2Y5YZM-JDNT4RM-ZOQVBZD-DUOAGQH";
    autoAcceptFolders = true;
  };
}
