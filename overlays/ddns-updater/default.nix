{ inputs, ... }: # TODO: does not update pkg.
self: prev: { # use unstable package
  ddns-updater = inputs.nixos-unstable.legacyPackages.${prev.stdenv.hostPlatform.system}.ddns-updater;
}
