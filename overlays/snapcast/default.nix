{ inputs, ... }:
self: prev: { # use old package with required `Stream.AddStream` count.
  # snapcast = prev.snapcast.overrideAttrs (old: rec { # seb NOTE: building this costs me too long, just use a legacy package
  #   version = "0.29.0";
  #   src = self.fetchFromGitHub {
  #     owner = "badaix";
  #     repo = "snapcast";
  #     rev = "v${version}";
  #     hash = "sha256-EJgpZz4PnXfge0rkVH1F7cah+i9AvDJVSUVqL7qChDM=";
  #   };
  # });
  snapcast = inputs.nixpkgs-24_05.legacyPackages.${prev.stdenv.hostPlatform.system}.snapcast;
}
