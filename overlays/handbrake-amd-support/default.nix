{ inputs, ... }:
self: prev: { # Patch foot with an option that allows per-monitor scaling, so that DPI and stuff isn't so horrible.
  handbrake = prev.handbrake.overrideAttrs (old: rec {
    # version = "1.16.2"; # maybe lock version
    configureFlags = old.configureFlags ++ [ "--enable-vce" ];
    buildInputs = old.buildInputs ++ [ prev.amf-headers ]; # maybe provide radeon-like interface?
    # seb: NOTE this isn't going to work without actually having amf installed. Also handbrake appears to ignore this flag.
  });
}
