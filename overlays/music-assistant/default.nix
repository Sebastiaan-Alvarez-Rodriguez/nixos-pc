{ inputs, ... }:
self: prev: {
  music-assistant = inputs.nixpkgs-unstable.legacyPackages.${prev.stdenv.hostPlatform.system}.music-assistant.overrideAttrs (old: {
    patches = old.patches ++ [ ./portfix.patch ];
  });
}
