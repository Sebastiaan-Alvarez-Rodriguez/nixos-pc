self: prev: { # Patch foot with an option that allows per-monitor scaling, so that DPI and stuff isn't so horrible.
  foot = prev.foot.overrideAttrs (old: rec {
    version = "1.16.2"; # Also use an older version so that we don't need to update the patches every time
    src = self.fetchFromGitea {
      domain = "codeberg.org";
      owner = "dnkl";
      repo = "foot";
      rev = version;
      hash = "sha256-hT+btlfqfwGBDWTssYl8KN6SbR9/Y2ors4ipECliigM=";
    };
    patches = (old.patches or [ ]) ++ [ ./foot-per-monitor-scale.patch ];
  });
}
