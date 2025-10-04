{ inputs, ... }:
self: prev: {
  music-assistant = inputs.nixpkgs-unstable.legacyPackages.${prev.stdenv.hostPlatform.system}.music-assistant.overrideAttrs (old: {
    patches = old.patches ++ [ ./portfix.patch ./refreezer.patch ./spotify.patch ] ++ [
      (prev.fetchpatch {
        url = "https://github.com/sweenu/music-assistant/commit/fa72831ed3c375a9e81baed9ac40e0d242a03c86.patch";
        hash = "sha256-GoVhhgnvzzig5gOHR7Vrs+i5oxqWHzOHPUgfBCppfWc=";
      })
    ]; # this patch (taken from https://github.com/NixOS/nixpkgs/issues/436670#issuecomment-3315287884) should be used until this is fixed: https://github.com/NixOS/nixpkgs/issues/436670
  });
}
