{ inputs, ... }: # TODO: does not update pkg.
self: prev: { # use unstable package
  unstable-ddns-updater = inputs.nixpkgs-unstable.legacyPackages.${prev.stdenv.hostPlatform.system}.ddns-updater;
}
