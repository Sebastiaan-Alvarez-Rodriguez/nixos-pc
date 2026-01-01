{ inputs, ... }:
self: prev: {
  # music-assistant = inputs.nixpkgs-unstable.legacyPackages.${prev.stdenv.hostPlatform.system}.music-assistant.overrideAttrs (old: {
    # patches = old.patches ++ [ ./portfix.patch ]; # seb NOTE:
    # add ./refreezer.patch add when wanting to have refreezer integration again
    # add ./spotify.patch to fix spotify signup behind integration.
  # });
}
