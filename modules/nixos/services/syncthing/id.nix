{age-secrets}: { # the IDs are not secret at all, src: https://forum.syncthing.net/t/should-i-keep-my-node-ids-as-secret-as-possible/230
  "helium" = {
    id = "FOGGQVK-QV6ZQRK-NUAE2D3-TCO7FSH-NAUPR6P-NGZ3II6-X57XYR2-EEBTRAH";
    private-keyfile = age-secrets."hosts/helium/services/syncthing/key".path;
    certfile = age-secrets."hosts/helium/services/syncthing/cert".path;
  };
}
